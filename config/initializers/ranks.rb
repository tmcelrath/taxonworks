# Be sure to restart your server when you modify this file.

 # ICN Rank Classes ordered in an Array
 ICN = Ranks.ordered_ranks_for(NomenclaturalRank::Icn)
 
 # ICZN Rank Classes ordered in an Array
 ICZN = Ranks.ordered_ranks_for(NomenclaturalRank::Iczn)

 # All assignable Rank Classes
 RANKS = [NomenclaturalRank] + ICN + ICZN

 # ICNZ Ranks, as Strings
 RANK_CLASS_NAMES_ICZN = ICZN.collect{|r| r.to_s}

 # ICN Ranks, as Strings
 RANK_CLASS_NAMES_ICN = ICN.collect{|r| r.to_s}

 # All Ranks, as Strings
 RANK_CLASS_NAMES = RANKS.collect{|r| r.to_s}

 # ICN Rank Classes in a Hash with keys being the "human" name
 # For example, to return the class for a plant family:
 #   ::ICN_LOOKUP['family']
 ICN_LOOKUP = ICN.inject({}){|hsh, r| hsh.merge!(r.rank_name => r)}
 
 # ICZN Rank Classes in a Hash with keys being the "human" name
 ICZN_LOOKUP = ICZN.inject({}){|hsh, r| hsh.merge!(r.rank_name => r)}

# All assignable ranks for family group and above family names, for both ICN and ICZN
FAMILY_AND_ABOVE_RANKS_NAMES = (NomenclaturalRank::Iczn::HigherClassificationGroup.descendants +
      NomenclaturalRank::Iczn::FamilyGroup.descendants +
      NomenclaturalRank::Icn::HigherClassificationGroup.descendants +
      NomenclaturalRank::Icn::FamilyGroup.descendants).collect{|i| i.to_s}

# All assignable ranks for family group, for both ICN and ICZN
FAMILY_RANKS_NAMES = (NomenclaturalRank::Iczn::FamilyGroup.descendants +
    NomenclaturalRank::Icn::FamilyGroup.descendants).collect{|i| i.to_s}

# All assignable ranks for genus groups, for both ICN and ICZN
GENUS_RANKS_NAMES = (NomenclaturalRank::Iczn::GenusGroup.descendants +
    NomenclaturalRank::Icn::GenusGroup.descendants).collect{|i| i.to_s}

# All assignable ranks for genus and species groups, for both ICN and ICZN
GENUS_AND_SPECIES_RANKS_NAMES = (NomenclaturalRank::Iczn::GenusGroup.descendants +
      NomenclaturalRank::Iczn::SpeciesGroup.descendants +
      NomenclaturalRank::Icn::GenusGroup.descendants +
      NomenclaturalRank::Icn::SpeciesAndInfraspeciesGroup.descendants).collect{|i| i.to_s}

# All assignable ranks for species groups, for both ICN and ICZN
SPECIES_RANKS_NAMES = (NomenclaturalRank::Iczn::SpeciesGroup.descendants +
    NomenclaturalRank::Icn::SpeciesAndInfraspeciesGroup.descendants).collect{|i| i.to_s}

# All assignable ranks for family groups, for ICZN
FAMILY_RANKS_NAMES_ICZN = NomenclaturalRank::Iczn::FamilyGroup.descendants.collect{|i| i.to_s}

# All assignable ranks for family groups, for both ICN
FAMILY_RANKS_NAMES_ICN = NomenclaturalRank::Icn::FamilyGroup.descendants.collect{|i| i.to_s}

# All assignable ranks for genus groups, for ICZN
GENUS_RANKS_NAMES_ICZN = NomenclaturalRank::Iczn::GenusGroup.descendants.collect{|i| i.to_s}

# All assignable ranks for genus groups, for both ICN
GENUS_RANKS_NAMES_ICN = NomenclaturalRank::Icn::GenusGroup.descendants.collect{|i| i.to_s}

# All assignable ranks for species groups, for ICZN
SPECIES_RANKS_NAMES_ICZN = NomenclaturalRank::Iczn::SpeciesGroup.descendants.collect{|i| i.to_s}

# All assignable ranks for species groups, for both ICN
SPECIES_RANKS_NAMES_ICN = NomenclaturalRank::Icn::SpeciesAndInfraspeciesGroup.descendants.collect{|i| i.to_s}

# All assignable ranks for genus and species groups, for both ICZN
GENUS_AND_SPECIES_RANKS_NAMES_ICZN = (NomenclaturalRank::Iczn::GenusGroup.descendants +
    NomenclaturalRank::Iczn::SpeciesGroup.descendants).collect{|i| i.to_s}

# All assignable ranks for genus and species groups, for both ICN
GENUS_AND_SPECIES_RANKS_NAMES_ICN = (NomenclaturalRank::Icn::GenusGroup.descendants +
    NomenclaturalRank::Icn::SpeciesAndInfraspeciesGroup.descendants).collect{|i| i.to_s}
