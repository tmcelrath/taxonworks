require 'fileutils'

namespace :tw do
  namespace :project_import do
    namespace :sf_taxa do

# import taxa
# original_genus_id: cannot set until all taxa (for a given project) are imported; and the out of scope taxa as well
# pass 1:
#         ok create SFTaxonNameIDToTWTaxonNameID hash;
#         ok save NameStatus, StatusFlags, in hashes as data_attributes or hashes?;
#         ok set rank according to sf_rank_id_to_tw_rank_string hash;
#         ok set classification if
#           nomen nudum = TaxonNameClassification::Iczn::Unavailable::NomenNudum (StatusFlags & 8 = 8 if NameStatus = 4 or 7),
#           nomen dubium = TaxonNameClassification::Iczn::Available::Valid::NomenDubium (StatusFlags & 16 = 16 if NameStatus = 5 or 7), and
#           fossil = TaxonNameClassification::Iczn::Fossil (extinct = 1)
#           (other classifications will probably have relationships)
#         ok add nomenclatural comment as TW.Note (in row['Comment']);
#         ok if temporary, make an OTU which has the TaxonNameID of the AboveID as the taxon name reference (or find the most recent valid above ID);
#         ok natural order is TaxonNameStr (must be in order to ensure synonym parent already imported);
#         ok for synonyms, use sf_synonym_id_to_parent_id_hash; create error message if not found (hash was created from dynamic tblTaxa later than .txt);
# ADD HOUSEKEEPING to _attributes

# 20160628
# Tasks before dumping and restoring db
#   ok Keep copy of current db with some taxa imported
#   Force Import hashes to be strings and change usage instances accordingly
#   ok Manually transfer three adjunct tables: RefIDToRefLink (probably table sfRefLinks which generates ref_id_to_ref_link.txt), sfVerbatimRefs and sfSynonymParents created by ScriptsFor1db2tw.sql
#   Make sure path references correct subdirectory (working vs. old)
#   ok Figure out how to assign myself as project member in each SF, what about universal user like 3i does??
#   ok Make sure none_species_file does not get created (FileID must be > 0)
#   ok Write get_tw_taxon_name_id to db! And three others...
#   ok Use TaxonNameClassification::Iczn::Unavailable::NotLatin for Name Name must be latinized, no digits or spaces allowed
#   no, use NotLatin: Use TaxonNameClassification::Iczn::Unavailable for non-latinized family group name synonyms
#   ok FixSFSynonymIDToParentID to iterate until Parent RankID > synonym RankID

# pass 2

      desc 'create all SF taxa (pass 1)'
      task :create_all_sf_taxa_pass1 => [:data_directory, :environment, :user_id] do
        ### time rake tw:project_import:sf_taxa:create_all_sf_taxa_pass1 user_id=1 data_directory=/Users/mbeckman/src/onedb2tw/working/

        puts 'Creating all SF taxa...'

        species_file_data = Import.find_or_create_by(name: 'SpeciesFileData')
        get_user_id = species_file_data.get('FileUserIDToTWUserID') # for housekeeping
        get_rank_string = species_file_data.get('SFRankIDToTWRankString')
        get_source_id = species_file_data.get('SFRefIDToTWSourceID')
        get_project_id = species_file_data.get('SFFileIDToTWProjectID')
        get_animalia_id = species_file_data.get('ProjectIDToAnimaliaID') # key = TW.Project.id, value TW.TaxonName.id where Name = 'Animalia', used when AboveID = 0
        get_synonym_parent_id = species_file_data.get('SFSynonymIDToParentID')

        get_tw_taxon_name_id = {} # SF.TaxonNameID to TW.TaxonNameID hash, key = SF.TaxonNameID, value = TW.taxon_name.id
        get_sf_name_status = {} # key = SF.TaxonNameID, value = SF.NameStatus
        get_sf_status_flags = {} # key = SF.TaxonNameID, value = SF.StatusFlags
        get_tw_otu_id = {} # key = SF.TaxonNameID, value = TW.otu.id; used for temporary SF taxa

        path = @args[:data_directory] + 'tblTaxa.txt'
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'UTF-16:UTF-8')

        error_counter = 0
        count_found = 0

        file.each_with_index do |row, i|
          taxon_name_id = row['TaxonNameID']
          next unless taxon_name_id.to_i > 0
          next if row['TaxonNameStr'].start_with?('1100048-1143863') # name = MiscImages (body parts)
          next if row['RankID'] == '90' # TaxonNameID = 1221948, Name = Deletable, RankID = 90 == Life, FileID = 1

          project_id = get_project_id[row['FileID']]

          count_found += 1
          print "Working with TW.project_id: #{project_id} = SF.FileID #{row['FileID']}, SF.TaxonNameID #{taxon_name_id} (count #{count_found}) \n"

          if row['AboveID'] == '0' # must check AboveID = 0 before synonym
            parent_id = get_animalia_id[project_id.to_s].to_i
          elsif row['NameStatus'] == '7' # = synonym
            parent_id = get_tw_taxon_name_id[get_synonym_parent_id[taxon_name_id]].to_i # assumes tw_taxon_name_id exists
          else
            parent_id = get_tw_taxon_name_id[row['AboveID']].to_i
          end

          if parent_id == nil
            puts '      ERROR: Could not find parent_id!'
            next
          end

          name_status = row['NameStatus']
          status_flags = row['StatusFlags']

          if name_status == '2' # temporary, create OTU, not TaxonName
            otu = Otu.new(
                name: row['Name'],
                taxon_name_id: parent_id,
                project_id: project_id,
                created_at: row['CreatedOn'],
                updated_at: row['LastUpdate'],
                created_by_id: get_user_id[row['CreatedBy']],
                updated_by_id: get_user_id[row['ModifiedBy']]
            )

            if otu.save
              puts "  Note!! Created OTU for temporary taxon, otu.id: #{otu.id}"
              get_tw_otu_id[row['TaxonNameID']] = otu.id
              get_sf_name_status[row['TaxonNameID']] = name_status
              get_sf_status_flags[row['TaxonNameID']] = status_flags

            else
              error_counter += 1
              puts "     OTU ERROR (#{error_counter}): " + otu.errors.full_messages.join(';')
              puts "  project_id: #{project_id}, SF.TaxonNameID: #{row['TaxonNameID']}, sf row created by: #{row['CreatedBy']}, sf row updated by: #{row['ModifiedBy']}    "
            end

          else
            fossil, nomen_nudum, nomen_dubium = nil
            fossil = 'TaxonNameClassification::Iczn::Fossil' if row['Extinct'] == '1'
            nomen_nudum = 'TaxonNameClassification::Iczn::Unavailable::NomenNudum' if status_flags.to_i & 8 == 8
            nomen_dubium = 'TaxonNameClassification::Iczn::Available::Valid::NomenDubium' if status_flags.to_i & 16 == 16

            taxon_name = Protonym.new(
                name: row['Name'],
                parent_id: parent_id,
                rank_class: get_rank_string[row['RankID']],

                # check housekeeping values; should citations, notes, classifications be attributed to SF last_editor?
                origin_citation_attributes: {source_id: get_source_id[row['RefID']],
                                             project_id: project_id,
                                             created_at: row['CreatedOn'],
                                             updated_at: row['LastUpdate'],
                                             created_by_id: get_user_id[row['CreatedBy']],
                                             updated_by_id: get_user_id[row['ModifiedBy']]},

                notes_attributes: [{text: (row['Comment'].blank? ? nil : row['Comment']),
                                    project_id: project_id,
                                    created_at: row['CreatedOn'],
                                    updated_at: row['LastUpdate'],
                                    created_by_id: get_user_id[row['CreatedBy']],
                                    updated_by_id: get_user_id[row['ModifiedBy']]}],

                # perhaps test for nil for each...  (Dmitry) classification.new? Dmitry prefers doing one at a time and validating?? And after the taxon is saved.
                taxon_name_classifications_attributes: [
                    {type: fossil, project_id: project_id,
                     created_at: row['CreatedOn'],
                     updated_at: row['LastUpdate'],
                     created_by_id: get_user_id[row['CreatedBy']],
                     updated_by_id: get_user_id[row['ModifiedBy']]},
                    {type: nomen_nudum, project_id: project_id,
                     created_at: row['CreatedOn'],
                     updated_at: row['LastUpdate'],
                     created_by_id: get_user_id[row['CreatedBy']],
                     updated_by_id: get_user_id[row['ModifiedBy']]},
                    {type: nomen_dubium, project_id: project_id,
                     created_at: row['CreatedOn'],
                     updated_at: row['LastUpdate'],
                     created_by_id: get_user_id[row['CreatedBy']],
                     updated_by_id: get_user_id[row['ModifiedBy']]}
                ],

                also_create_otu: true, # pretty nifty way to automatically make an OTU!

                project_id: project_id,
                created_at: row['CreatedOn'],
                updated_at: row['LastUpdate'],
                created_by_id: get_user_id[row['CreatedBy']],
                updated_by_id: get_user_id[row['ModifiedBy']]
            )
          end

          # if taxon_name.save
          if taxon_name.valid?
            taxon_name.save!
            get_tw_taxon_name_id[row['TaxonNameID']] = taxon_name.id
            get_sf_name_status[row['TaxonNameID']] = name_status
            get_sf_status_flags[row['TaxonNameID']] = status_flags


            # test if valid before save; if one of anticipated import errors, add classification, then try to save again...

            # Dmitry's code:
            # if taxon.valid?
            #   taxon.save!
            #   @data.taxon_index.merge!(row['Key'] => taxon.id)
            # else
            #   taxon.taxon_name_classifications.new(type: 'TaxonNameClassification::Iczn::Unavailable::NotLatin') if taxon.rank_string =~ /Family/ && row['Status'] != '0' && !taxon.errors.messages[:name].blank?
            #   taxon.taxon_name_classifications.new(type: 'TaxonNameClassification::Iczn::Unavailable::NotLatin') if taxon.rank_string =~ /Species/ && row['Status'] != '0' && taxon.errors.full_messages.include?('Name name must be lower case')
            #   taxon.taxon_name_classifications.new(type: 'TaxonNameClassification::Iczn::Unavailable::NotLatin') if taxon.rank_string =~ /Species/ && row['Status'] != '0' && taxon.errors.full_messages.include?('Name Name must be latinized, no digits or spaces allowed')
            #   taxon.taxon_name_classifications.new(type: 'TaxonNameClassification::Iczn::Unavailable::NotLatin') if taxon.rank_string =~ /Genus/ && row['Status'] != '0' && taxon.errors.full_messages.include?('Name Name must be latinized, no digits or spaces allowed')
            #
            #   if taxon.valid?
            #     taxon.save!
            #     @data.taxon_index.merge!(row['Key'] => taxon.id)
            #   else
            #     print "\n#{row['Key']}         #{row['Name']}"
            #     print "\n#{taxon.errors.full_messages}\n"
            #     #byebug
            #   end
            # end of Dmitry's code

            #
            # case taxon_name.errors.full_messages.include?
            # when 'Name name must end in -oidea', 'Name name must end in -idae', 'Name name must end in ini', 'Name name must end in -inae'
            # and row['NameStatus'] == '7'
            # taxon_name.taxon_name_classifications.new(type: 'TaxonNameClassification::Iczn::Unavailable')

            #
            # when 'Name Name must be latinized, no digits or spaces allowed'
            # and row['NameStatus'] == '7'
            # taxon_name.taxon_name_classifications.new(type: 'TaxonNameClassification::Iczn::NotLatin')

          elsif row['NameStatus'] == '7' # make all NotLatin... Dmitry Add project_id
            case taxon_name.errors.full_messages.include? # ArgumentError: wrong number of arguments (given 0, expected 1)
              when 'Name name must end in -oidea', 'Name name must end in -idae', 'Name name must end in ini', 'Name name must end in -inae'
                taxon_name.taxon_name_classifications.new(type: 'TaxonNameClassification::Iczn::Unavailable')
              when 'Name Name must be latinized, no digits or spaces allowed'
                taxon_name.taxon_name_classifications.new(type: 'TaxonNameClassification::Iczn::NotLatin')
            end
          end

          if taxon_name.valid?
            taxon_name.save! # taxon won't be saved if something wrong with classifications_attributes, read about !
            get_tw_taxon_name_id[row['TaxonNameID']] = taxon_name.id
            get_sf_name_status[row['TaxonNameID']] = name_status
            get_sf_status_flags[row['TaxonNameID']] = status_flags

          else
            error_counter += 1
            puts "     TaxonName ERROR (#{error_counter}): " + taxon_name.errors.full_messages.join(';')
            puts "  project_id: #{project_id}, SF.TaxonNameID: #{row['TaxonNameID']}, sf row created by: #{row['CreatedBy']}, sf row updated by: #{row['ModifiedBy']}    "
          end
        end

        species_file_data.set('SFTaxonNameIDToTWTaxonNameID', get_tw_taxon_name_id)
        species_file_data.set('SFTaxonNameIDToSFNameStatus', get_sf_name_status)
        species_file_data.set('SFTaxonNameIDToSFStatusFlags', get_sf_status_flags)
        species_file_data.set('SFTaxonNameIDToTWOtuID', get_tw_otu_id)

        puts 'SFTaxonNameIDToTWTaxonNameID'
        ap get_tw_taxon_name_id
        puts 'SFTaxonNameIDToSFNameStatus'
        ap get_sf_name_status
        puts 'SFTaxonNameIDToSFStatusFlags'
        ap get_sf_status_flags
        puts 'SFTaxonNameIDToTWOtuID'
        ap get_tw_otu_id

      end

      desc 'create SF synonym.id to parent.id hash'
      task :create_sf_synonym_id_to_parent_id_hash => [:data_directory, :environment, :user_id] do
        ### time rake tw:project_import:sf_taxa:create_sf_synonym_id_to_parent_id_hash user_id=1 data_directory=/Users/mbeckman/src/onedb2tw/working/

        puts 'Running SF synonym parent hash...'

        sf_synonym_id_to_parent_id_hash = {}

        path = @args[:data_directory] + 'sfSynonymParents.txt'
        file = CSV.read(path, col_sep: "\t", headers: true, encoding: 'BOM|UTF-8')

        file.each do |row|
          # byebug
          # puts row.inspect
          taxon_name_id = row['TaxonNameID']
          print "working with #{taxon_name_id} \n"
          sf_synonym_id_to_parent_id_hash[taxon_name_id] = row['NewAboveID']
        end

        i = Import.find_or_create_by(name: 'SpeciesFileData')
        i.set('SFSynonymIDToParentID', sf_synonym_id_to_parent_id_hash)

        puts 'SFSynonymIDToParentID'
        ap sf_synonym_id_to_parent_id_hash

      end

      desc 'create Animalia taxon name subordinate to each project Root (and make hash of project.id, animalia.id'
      # creating project_id_animalia_id_hash
      task :create_animalia_below_root => [:data_directory, :environment, :user_id] do
        ### time rake tw:project_import:sf_taxa:create_animalia_below_root user_id=1 data_directory=/Users/mbeckman/src/onedb2tw/working/

        species_file_data = Import.find_or_create_by(name: 'SpeciesFileData')
        get_project_id = species_file_data.get('SFFileIDToTWProjectID')

        project_id_animalia_id_hash = {} # hash of TW.project_id (key), TW.taxon_name_id = 'Animalia' (value)

        TaxonName.first # a royal kludge to ensure taxon_name plumbing is in place v-a-v project

        get_project_id.values.each_with_index do |project_id, index|
          next if index == 0 # hash accidently included FileID = 0
          # puts "before root = (index = #{index}, project_id = #{project_id})"
          # puts "after this_project assignment #{this_project.id}"
          # puts "this_project.name: #{this_project.root_taxon_name.name}; this_project.name.id: #{this_project.root_taxon_name.id}!"
          next if TaxonName.find_by(project_id: project_id, name: 'Animalia') # test if Animalia already exists

          this_project = Project.find(project_id)
          puts "working with project.id: #{project_id}, root_name: #{this_project.root_taxon_name.name}, root_name_id: #{this_project.root_taxon_name.id}"

          animalia_taxon_name = Protonym.new(
              name: 'Animalia',
              parent_id: this_project.root_taxon_name.id,
              rank_class: NomenclaturalRank::Iczn::HigherClassificationGroup::Kingdom,
              project_id: project_id,
              created_at: Time.now,
              updated_at: Time.now,
              created_by_id: $user_id,
              updated_by_id: $user_id
          )

          if animalia_taxon_name.save
            project_id_animalia_id_hash[project_id] = animalia_taxon_name.id
          end
        end

        i = Import.find_or_create_by(name: 'SpeciesFileData')
        i.set('ProjectIDToAnimaliaID', project_id_animalia_id_hash)

        puts "ProjectIDToAnimaliaID"
        ap project_id_animalia_id_hash

      end

      desc 'create rank hash'
      ### time rake tw:project_import:sf_taxa:create_rank_hash user_id=1 data_directory=/Users/mbeckman/src/onedb2tw/working/
      task :create_rank_hash => [:data_directory, :environment, :user_id] do
        # Can be run independently at any time

        puts 'Running create_rank_hash...'

        get_tw_rank_string = {} # key = SF.RankID, value = TW.rank_string (Ranks.lookup(SF.Rank.Name))

        path = @args[:data_directory] + 'tblRanks.txt'
        file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'UTF-16:UTF-8')

        file.each_with_index do |row, i|
          rank_id = row['RankID']
          next if ['90', '100'].include?(rank_id) # RankID = 0, "not specified", will = nil

          get_tw_rank_string[rank_id] = Ranks.lookup(:iczn, row['RankName'])
        end

        import = Import.find_or_create_by(name: 'SpeciesFileData')
        import.set('SFRankIDToTWRankString', get_tw_rank_string)

        puts = 'SFRankIDToTWRankString'
        ap get_tw_rank_string
      end
    end
  end
end




