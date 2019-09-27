module Queries
  module TaxonName 

    # Sumamrize nomenclature across specific ranks. 
    class Tabular < Queries::Query

      attr_accessor :ancestor_id

      attr_accessor :ancestor

      # @return [ query execution result ]
      attr_accessor :query

      # @return [Array]
      #   like 'family', 'genus', 'species
      # ORDER IS IMPORTANT
      attr_accessor :ranks

      # @return [Array of Strings]
      #  named sets of columns to include
      #  valid values are 
      #    - observations
      attr_accessor :fieldsets

      attr_accessor :projected_fields

      attr_accessor :column_headers

      attr_accessor :validity

      # @param params [Params] 
      #   a permitted via controller
      def initialize(params)
        super(nil, params)

        @ranks = params[:ranks] 
        @ancestor_id = params[:ancestor_id]
        @ancestor = ::Protonym.where(project_id: project_id).find(ancestor_id)

        @fieldsets = params[:fieldsets] || []
        @column_headers = ['generations', 'otu_id', 'taxon_name_id', 'cached'] + ranks 

        @validity = (params[:validity]&.downcase == 'true' ? true : false) if !params[:validity].nil?

        build_query
      end

      def table
        ::TaxonName.arel_table
      end 

      def hierarchy_table
        Arel::Table.new(:taxon_name_hierarchies)
      end

      def otu_table
        ::Otu.arel_table
      end

      def build_query
        h = hierarchy_table

        fields = {}
        fields2 = [] 
        rank_joins = []

        ranks.each_with_index do |r, i|
          rank_joins.push table.alias("j_#{i}")
        end
        q = h.where(h[:ancestor_id].eq(ancestor_id))

        rank_joins.each_with_index do |t, i|
          t = t.where(t[:cached_taxon_name_id].eq(t[:id])) if validity
          q = q.join(t, Arel::Nodes::OuterJoin)
            .on(t[:id].eq(h[:descendant_id]).
                and(t[:rank_class].eq( Ranks.lookup(ancestor.nomenclatural_code, ranks[i]))))

          fields[ ranks[i]] = t[:name].as( ranks[i] )
          fields2.push t[:id]
        end

        fields2.reverse!
        v = coalesce_ranks(fields2)

        q = q.join(otu_table, Arel::Nodes::OuterJoin).on(otu_table[:taxon_name_id].eq( v ))

        @projected_fields = [
          h[:generations].as('generations'), 
          otu_table[:id].as('otu_id'),
          coalesce_ranks(fields2).as('taxon_name_id'),
          coalesce_ranks(rank_joins.reverse.collect{|j| j[:cached]}).as('cached'),
        ] + fields.values

        fieldsets.each do |f|
          q = send(f + '_set', q) 
        end

        @query = q.distinct.project( *@projected_fields ).order(h[:generations], *fields.keys)
      end

      def coalesce_ranks(fields)
        Arel::Nodes::NamedFunction.new('coalesce', [fields])
      end

      def all
        ApplicationRecord.connection.execute(@query.to_sql)
      end

      # TODO: break out fieldset to its own concern
      def observations_set(query)
        @projected_fields.push '"fs_o1"."observation_count" as observation_count'
        @column_headers.push 'observation_count'
        o = ::Observation.arel_table
        x = o.project(
          o[:otu_id], 
          o[:otu_id].count.as('observation_count')
        ).group(o[:otu_id]).as('fs_o1')

        query.join(x, Arel::Nodes::OuterJoin).on(x[:otu_id].eq(otu_table[:id]))

        @projected_fields.push '"fs_o2"."observation_depictions" as observation_depictions'
        @column_headers.push 'observation_depictions'
        p = ::Depiction.arel_table
        y = p.join(o, Arel::Nodes::OuterJoin).on(
          p[:depiction_object_id].eq(o[:otu_id])).where(p[:depiction_object_type].eq('Observation'))
          .project(
            p[:depiction_object_id], 
            p[:depiction_object_id].count.as('observation_depictions')
        ).group(p[:depiction_object_id]).as('fs_o2')

        query.join(y, Arel::Nodes::OuterJoin).on(y[:depiction_object_id].eq(otu_table[:id]))

        @projected_fields.push '"fs_d1"."descriptors_scored" as descriptors_scored'
        @column_headers.push 'descriptors_scored'
        z = o.project(
          o[:otu_id], 
          o[:descriptor_id].count.as('descriptors_scored')
        ).group(o[:otu_id]).as('fs_d1')

        query.join(z, Arel::Nodes::OuterJoin).on(z[:otu_id].eq(otu_table[:id]))
      end

    end
  end
end