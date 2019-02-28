module Queries
  module CollectionObject
    class Autocomplete < Queries::Query

      # @params string [String]
      # @params [Hash] args
      def initialize(string, project_id: nil)
        super
      end

      def base_query
        ::CollectionObject.select('collection_objects.*')
      end

      # @return [Arel::Table]
      def taxon_name_table
        ::TaxonName.arel_table
      end

      # @return [Arel::Table]
      def otu_table
        ::Otu.arel_table
      end

      # @return [Arel::Table]
      def table
        ::CollectionObject.arel_table
      end

      def autocomplete_taxon_name_determined_as
        t = taxon_name_table[:name].matches_any(terms).or(taxon_name_table[:cached].matches_any(terms) )

        ::CollectionObject.
          includes(:identifiers, taxon_determinations: [otu: :taxon_name]).
          joins(taxon_determinations: [:otu]).
          where(t.to_sql).
          references(:taxon_determinations, :otus, :taxon_names).
          order('otus.name ASC').limit(10)
      end

      def autocomplete_otu_determined_as
        t = otu_table[:name].matches_any(terms)

        ::CollectionObject.
          joins(taxon_determinations: [:otu]).
          where(t.to_sql).references(:taxon_determinations, :otus).
          order('otus.name ASC').limit(10) 
      end

      # @return [Array]
      #   TODO: optimize limits
      def autocomplete
        queries = [
          autocomplete_identifier_cached_exact,
          autocomplete_identifier_cached_like,
          autocomplete_taxon_name_determined_as,
          autocomplete_otu_determined_as
        ]

        queries.compact! 

        return [] if queries.nil?
        updated_queries = []

        queries.each_with_index do |q ,i|
          a = q.where(project_id: project_id) if project_id
          a ||= q 
          updated_queries[i] = a
        end

        result = []
        updated_queries.each do |q|
          result += q.to_a
          result.uniq!
          break if result.count > 39 
        end
        result[0..39]
      end

    end
  end
end