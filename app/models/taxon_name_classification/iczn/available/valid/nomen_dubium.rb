class TaxonNameClassification::Iczn::Available::Valid::NomenDubium < TaxonNameClassification::Iczn::Available::Valid

  NOMEN_URI='http://purl.obolibrary.org/obo/NOMEN_0000225'.freeze

  def self.disjoint_taxon_name_classes
    self.parent.disjoint_taxon_name_classes + self.collect_to_s(
        TaxonNameClassification::Iczn::Available::Valid) + self.collect_to_s(
        TaxonNameClassification::Iczn::Available::Valid::NomenInquirendum)
  end

  def self.gbif_status
    'dubimum'
  end

  def sv_not_specific_classes
    true
  end
end
