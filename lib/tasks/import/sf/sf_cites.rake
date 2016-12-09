namespace :tw do
  namespace :project_import do
    namespace :sf_import do
      require 'fileutils'
      require 'logged_task'
      namespace :cites do

        desc 'time rake tw:project_import:sf_import:cites:create_citations user_id=1 data_directory=/Users/mbeckman/src/onedb2tw/working/'
        LoggedTask.define :create_some_related_taxa => [:data_directory, :environment, :user_id] do |logger|

          logger.info 'Creating citations...'

          import = Import.find_or_create_by(name: 'SpeciesFileData')
          get_tw_user_id = import.get('SFFileUserIDToTWUserID') # for housekeeping
          get_tw_taxon_name_id = import.get('SFTaxonNameIDToTWTaxonNameID')
          get_tw_otu_id = import.get('SFTaxonNameIDToTWOtuID')
          get_tw_source_id = import.get('SFRefIDToTWSourceID')
          get_nomenclator_string = import.get('SFNomenclatorIDToSFNomenclatorString')

          # @todo: Temporary "fix" to convert all values to string; will be fixed next time taxon names are imported and following do can be deleted
          get_tw_taxon_name_id.each do |key, value|
            get_tw_taxon_name_id[key] = value.to_s
          end

          path = @args[:data_directory] + 'tblCites.txt'
          file = CSV.foreach(path, col_sep: "\t", headers: true, encoding: 'UTF-16:UTF-8')

          count_found = 0
          error_counter = 0
          no_taxon_counter = 0
          cite_found_counter = 0

          file.each_with_index do |row, i|
            taxon_name_id = get_tw_taxon_name_id[row['TaxonNameID']].to_i
            # next unless TaxonName.where(id: taxon_name_id).any?

            if !TaxonName.where(id: taxon_name_id).exists?
              logger.warn "SF.TaxonNameID = #{row['TaxonNameID']} was not created in TW (no_taxon_counter = #{no_taxon_counter += 1})"

              # @todo: Test if OTU exists? Add citation to OTU?


              next
            end

            project_id = TaxonName.find(taxon_name_id).project_id.to_i
            source_id = get_tw_source_id[row['RefID']].to_i

            logger.info "Working with TW.project_id: #{project_id}, SF.TaxonNameID #{row['TaxonNameID']} = TW.taxon_name_id #{taxon_name_id},
SF.RefID #{row['RefID']} = TW.source_id #{row['']}, SF.SeqNum #{row['SeqNum']} (count #{count_found += 1}) \n"

            cite_pages = row['CitePages']

            # Original description citation most likely already exists but pages are source pages, not cite pages
            if citation == Citation.where(source_id: source_id, citation_object_type: 'TaxonName', citation_object_id: taxon_name_id, is_original: true).first
              citation.notes << Note.new(text: row['Note'], project_id: project_id) unless row['Note'].blank? # project_id? ; what is << ?
              citation.update_column(:pages, cite_pages) # update pages to cite_pages
              logger.info "Citation found: citation.id = #{citation.id}, taxon_name_id = #{taxon_name_id}, cite_pages = '#{cite_pages}' (cite_found_counter = #{cite_found_counter += 1}"

            else # create new citation
              citation = Citation.new(
                  source_id: source_id,
                  pages: cite_pages,
                  is_original: (row['SeqNum'] == '1' ? true : false),
                  citation_object_type: 'TaxonName',
                  citation_object_id: taxon_name_id,

                  ## Note: Add as attribute before save citation
                  notes_attributes: [{text: row['Note'], # (row['Note'].blank? ? nil :   rejected automatically by notable
                                      project_id: project_id,
                                      created_at: row['CreatedOn'],
                                      updated_at: row['LastUpdate'],
                                      created_by_id: get_tw_user_id[row['CreatedBy']],
                                      updated_by_id: get_tw_user_id[row['ModifiedBy']]}],

                  ## NewNameStatus: As tags to citations, create 16 keywords for each project, set up in case statement; test for NewNameStatusID > 0
                  ## TypeInfo: As tags to citations, create n keywords for each project, set up in case statement (2364 cases!)
                  tags_attributes: [
                      {keyword_id: (row['NewNameStatus'].to_i > 0 ? ControlledVocabularyTerm.where('uri LIKE ? and project_id = ?', "%/new_name_status/#{row['NewNameStatus']}", project_id).limit(1).pluck(:id).first : nil), project_id: project_id},
                      {keyword_id: (row['TypeInfoID'].to_i > 0 ? ControlledVocabularyTerm.where('uri LIKE ? and project_id = ?', "%/type_info/#{row['TypeInfoID']}", project_id).limit(1).pluck(:id).first : nil), project_id: project_id}
                  ],

                  ## InfoFlagStatus: Add confidence, 1 = partial data or needs review, 2 = complete data
                  confidences_attributes: [{confidence_level_id: (row['InfoFlagStatus'].to_i > 0 ? ControlledVocabularyTerm.where('uri LIKE ? and project_id = ?', "%/info_flag_status/#{row['InfoFlagStatus']}", project_id).limit(1).pluck(:id).first : nil), project_id: project_id}],


                  # housekeeping for citation
                  project_id: project_id,
                  created_at: row['CreatedOn'],
                  updated_at: row['LastUpdate'],
                  created_by_id: get_tw_user_id[row['CreatedBy']],
                  updated_by_id: get_tw_user_id[row['ModifiedBy']]
              )

              begin
                citation.save!
                logger.info "Citation saved"
              rescue ActiveRecord::RecordInvalid # citation not valid
                logger.info "Citation ERROR (#{error_counter += 1}): " + citation.errors.full_messages.join(';')
                next
              end
            end


            ### After citation updated or created

            ## Nomenclator: DataAttribute of citation, NomenclatorID > 0
            if row['NomenclatorID'] != '0' # OR could value: be evaluated below based on NomenclatorID?
              da = DataAttribute.new(type: 'ImportAttribute',
                                     attribute_subject_id: citation.id,
                                     attribute_subject_type: 'Citation',
                                     # attribute_subject: citation,        replaces two lines above
                                     import_predicate: 'Nomenclator',
                                     value: get_nomenclator_string[row['NomenclatorID']],
                                     project_id: project_id,
                                     created_at: row['CreatedOn'],
                                     updated_at: row['LastUpdate'],
                                     created_by_id: get_tw_user_id[row['CreatedBy']],
                                     updated_by_id: get_tw_user_id[row['ModifiedBy']]
              )
              begin
                da.save!
                puts 'DataAttribute Nomenclator created'
              rescue ActiveRecord::RecordInvalid # da not valid
                logger.error "DataAttribute Nomenclator ERROR NomenclatorID = #{row['NomenclatorID']}, SF.TaxonNameID #{row['TaxonNameID']} = TW.taxon_name_id #{taxon_name_id} (#{error_counter += 1}): " + da.errors.full_messages.join(';')
              end
            end


            ## ConceptChange: For now, do not import, only 2000 out of 31K were not automatically calculated, downstream in TW we will use Euler


            ## CurrentConcept: bit: For now, do not import
            # select * from tblCites c inner join tblTaxa t on c.TaxonNameID = t.TaxonNameID where c.CurrentConcept = 1 and t.NameStatus = 7


            ## InfoFlags: Attribute/topic of citation?!! Treat like StatusFlags for individual values
            # @todo: use as topics on citations for OTUs, make duplicate citation on OTU, then topic on that citation

            # inner loop on each citation to iterate through multiple topics contained in bitwise InfoFlags

            otu = get_tw_otu_id[taxon_name_id]

            otu_citation = citation.dup
            citation.citation_object = otu
            begin
              otu_citation.save!
            rescue ActiveRecord::RecordInvalid # otu_citation not valid
              logger.error = "Citation for OTU failed, etc."
            end


            # citation.dup
            # citation.citation_object = my_otu
            # citation.save

            info_flags = row['InfoFlags'].to_i

            if info_flags > 0
              cite_info_flags_array = Utilities::Numbers.get_bits(info_flags)

              cite_info_flags_array.each do |bit_position|

                # only need something like tags above, value is simply based on uri

                #cite_topic = CitationtTopic.save(
                cite_topic = CitationTopic.new(
                    topic_id: ControlledVocabularyTerm.where('uri LIKE ? and id = ?', "%/cite_info_flags/#{bit_position}", project_id).pluck(:id).first,
                    citation_id: citation.id,
                    project_id: project_id
                )
              end
            end


            ## PolynomialStatus: based on NewNameStatus: Used to detect "fake" (previous combos) synonyms
            # Not included in initial import; after import, in TW, when we calculate CoL output derived from OTUs, and if CoL output is clearly wrong then revisit this issue

          end
        end


        desc 'time rake tw:project_import:sf_import:cites:create_cvts_for_citations user_id=1 data_directory=/Users/mbeckman/src/onedb2tw/working/'
        # @todo Do I really need a data_directory if I'm using a Postgres table? Not that it hurts...
        LoggedTask.define :create_cvts_for_citations => [:data_directory, :environment, :user_id] do |logger|

          # Create controlled vocabulary terms (CVTS) for NewNameStatus, TypeInfo, and CiteInfoFlags; CITES_CVTS below in all caps denotes constant

          CITES_CVTS = {

              new_name_status: [
                  {name: 'unchanged', definition: 'Status of name did not change', uri: 'http://speciesfile.org/legacy/new_name_status/1', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'new name', definition: 'New name, unneeded emendation or subsequent mispelling', uri: 'http://speciesfile.org/legacy/new_name_status/2', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'made synonym', definition: 'Status of name changed to synonym', uri: 'http://speciesfile.org/legacy/new_name_status/3', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'made valid or temporary', definition: 'Name treated as valid or temporary', uri: 'http://speciesfile.org/legacy/new_name_status/4', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'new combination', definition: 'Remains valid in new combination', uri: 'http://speciesfile.org/legacy/new_name_status/5', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'new nomen nudum', definition: 'Name is a new nomen nudum', uri: 'http://speciesfile.org/legacy/new_name_status/6', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'nomen dubium', definition: 'Name treated as nomen dubium', uri: 'http://speciesfile.org/legacy/new_name_status/7', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'missed previous change', definition: 'Apparently missed a previous change', uri: 'http://speciesfile.org/legacy/new_name_status/8', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'still synonym, but of different taxon', definition: 'Name remains a synonym , but of different taxon', uri: 'http://speciesfile.org/legacy/new_name_status/9', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'gender change', definition: 'Name changed to match gender of genus', uri: 'http://speciesfile.org/legacy/new_name_status/10', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'new corrected name', definition: 'Justified emendation, corrected lapsus, or nomen nudum made available', uri: 'http://speciesfile.org/legacy/new_name_status/17', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'different combination', definition: 'Remains valid in restored combination', uri: 'http://speciesfile.org/legacy/new_name_status/18', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'made valid in new combination', definition: 'Made valid in new or different combination', uri: 'http://speciesfile.org/legacy/new_name_status/19', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'incorrect name before correct', definition: 'Nomen nudum, incorrect spelling or lapsus before proper name', uri: 'http://speciesfile.org/legacy/new_name_status/20', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'misapplied name', definition: 'Misapplied name used for misidentified specimen', uri: 'http://speciesfile.org/legacy/new_name_status/22', uri_relation: 'skos:closeMatch', type: 'Keyword'},
              ],

              type_info: [
                  {name: 'unspecified type information', definition: 'unspecified type information', uri: 'http://speciesfile.org/legacy/type_info/1', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'ruling by Commission', definition: 'ruling by Commission', uri: 'http://speciesfile.org/legacy/type_info/2', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'designated syntypes', definition: 'designated syntypes', uri: 'http://speciesfile.org/legacy/type_info/11', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'designated holotype', definition: 'designated holotype', uri: 'http://speciesfile.org/legacy/type_info/12', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'designated lectotype', definition: 'designated lectotype', uri: 'http://speciesfile.org/legacy/type_info/13', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'designated neotype', definition: 'designated neotype', uri: 'http://speciesfile.org/legacy/type_info/14', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'removed syntype(s)', definition: 'removed syntype(s)', uri: 'http://speciesfile.org/legacy/type_info/15', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'original monotypy', definition: 'original monotypy', uri: 'http://speciesfile.org/legacy/type_info/21', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'original designation', definition: 'original designation', uri: 'http://speciesfile.org/legacy/type_info/22', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'subsequent designation', definition: 'subsequent designation', uri: 'http://speciesfile.org/legacy/type_info/23', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'monotypy and original designation', definition: 'monotypy and original designation', uri: 'http://speciesfile.org/legacy/type_info/24', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'removed potential type(s)', definition: 'removed potential type(s)', uri: 'http://speciesfile.org/legacy/type_info/25', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'absolute tautonomy', definition: 'absolute tautonomy', uri: 'http://speciesfile.org/legacy/type_info/26', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'Linnaean tautonomy', definition: 'Linnaean tautonomy', uri: 'http://speciesfile.org/legacy/type_info/27', uri_relation: 'skos:closeMatch', type: 'Keyword'},
                  {name: 'inherited from replaced name', definition: 'inherited from replaced name', uri: 'http://speciesfile.org/legacy/type_info/29', uri_relation: 'skos:closeMatch', type: 'Keyword'},
              ],

              # uri end number represents bit position, not value
              cite_info_flags: [
                  {name: 'Image or description', definition: 'An image or description is included', uri: 'http://speciesfile.org/legacy/cite_info_flags/0', uri_relation: 'skos:closeMatch', type: 'Topic'},
                  {name: 'Phylogeny or classification', definition: 'An evolutionary relationship or hierarchical position is presented or discussed', uri: 'http://speciesfile.org/legacy/cite_info_flags/1', uri_relation: 'skos:closeMatch', type: 'Topic'},
                  {name: 'Ecological data', definition: 'Ecological data are included', uri: 'http://speciesfile.org/legacy/cite_info_flags/2', uri_relation: 'skos:closeMatch', type: 'Topic'},
                  {name: 'Specimen or distribution', definition: 'Specimen or distribution information is included', uri: 'http://speciesfile.org/legacy/cite_info_flags/3', uri_relation: 'skos:closeMatch', type: 'Topic'},
                  {name: 'Key', definition: 'A key for identification is included', uri: 'http://speciesfile.org/legacy/cite_info_flags/4', uri_relation: 'skos:closeMatch', type: 'Topic'},
                  {name: 'Life history', definition: 'Life history information is included', uri: 'http://speciesfile.org/legacy/cite_info_flags/5', uri_relation: 'skos:closeMatch', type: 'Topic'},
                  {name: 'Behavior', definition: 'Behavior information is included', uri: 'http://speciesfile.org/legacy/cite_info_flags/6', uri_relation: 'skos:closeMatch', type: 'Topic'},
                  {name: 'Economic matters', definition: 'Economic matters are included', uri: 'http://speciesfile.org/legacy/cite_info_flags/7', uri_relation: 'skos:closeMatch', type: 'Topic'},
                  {name: 'Physiology', definition: 'Physiology is included', uri: 'http://speciesfile.org/legacy/cite_info_flags/8', uri_relation: 'skos:closeMatch', type: 'Topic'},
                  {name: 'Structure', definition: 'Anatomy, cytology, genetic or other structural information is included', uri: 'http://speciesfile.org/legacy/cite_info_flags/9', uri_relation: 'skos:closeMatch', type: 'Topic'},
              ],

              info_flag_status: [
                  {name: 'partial data or needs review', definition: 'partial data or needs review', uri: 'http://speciesfile.org/legacy/info_flag_status/1', uri_relation: 'skos:closeMatch', type: 'ConfidenceLevel'},
                  {name: 'complete data', definition: 'complete data', uri: 'http://speciesfile.org/legacy/info_flag_status/2', uri_relation: 'skos:closeMatch', type: 'ConfidenceLevel'},
              ]

          }

          logger.info 'Running create_cvts_for_citations...'

          Project.all.each do |project|
            next unless project.name.end_with?('species_file')

            logger.info "Working with TW.project_id: #{project.id} = '#{project.name}'"

            ## commented out example using array ??
            # CITES_CVTS.keys.each do |key|
            #   CITES_CVTS[key].each do |params|
            #     ControlledVocabularyTerm.create!(params.merge(project_id: project_id))
            #   end
            # end

            CITES_CVTS.keys.each do |column| # tblCites.ColumnName
              CITES_CVTS[column].each do |params|
                ControlledVocabularyTerm.create!(params.merge(project_id: project.id))
              end
            end

          end
        end

        desc 'time rake tw:project_import:sf_import:cites:import_nomenclator_strings user_id=1 data_directory=/Users/mbeckman/src/onedb2tw/working/'
        LoggedTask.define :import_nomenclator_strings => [:data_directory, :environment, :user_id] do |logger|
          # Can be run independently at any time

          logger.info 'Running import_nomenclator_strings...'

          get_nomenclator_string = {} # key = SF.NomenclatorID, value = SF.nomenclator_string

          count_found = 0

          path = @args[:data_directory] + 'sfNomenclatorStrings.txt'
          file = CSV.read(path, col_sep: "\t", headers: true, encoding: 'BOM|UTF-8')

          file.each_with_index do |row, i|
            nomenclator_id = row['NomenclatorID']
            next if nomenclator_id == '0'

            nomenclator_string = row['NomenclatorString']

            logger.info "Working with SF.NomenclatorID '#{nomenclator_id}', SF.NomenclatorString '#{nomenclator_string}' (count #{count_found += 1}) \n"

            get_nomenclator_string[nomenclator_id] = nomenclator_string
          end

          import = Import.find_or_create_by(name: 'SpeciesFileData')
          import.set('SFNomenclatorIDToSFNomenclatorString', get_nomenclator_string)

          puts = 'SFNomenclatorIDToSFNomenclatorString'
          ap get_nomenclator_string
        end

      end
    end
  end
end
