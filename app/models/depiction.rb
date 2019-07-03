# A depiction is the linkage between an image and a data object.  For example
# an image may depiction a ColletingEvent, CollectionObject, or OTU.
#
# @!attribute depiction_object_type
#   @return [String]
#     the type of object being depicted, a TW class that can be depicted (e.g. CollectionObject, CollectingEvent)
#
# @!attribute depiction_object_id
#   @return [Integer]
#     the id of the object being depicted
#
# @!attribute image_id
#   @return [Integer]
#     the id of the image that stores the depiction
#
# @!attribute project_id
#   @return [Integer]
#     the project ID
#
# @!attribute svg_clip
#   @return [xml, nil]
#     a clipping mask to isolate some portion of the picture
#
# @!attribute is_metadata_depiction
#   @return [Boolean, nil]
#      If true then this depiction depicts data that describes the entity, rather than the entity itself.
#      For example, a CollectionObject depiction of a insect, vs. a picture of some text that says "the specimen is blue"
#
class Depiction < ApplicationRecord
  # TODO: add position scoping

  include Housekeeping
  include Shared::Tags
  include Shared::DataAttributes
  include Shared::IsData
  include Shared::PolymorphicAnnotator
  polymorphic_annotates(:depiction_object)

  acts_as_list scope: [:project_id, :depiction_object_type, :depiction_object_id]

  belongs_to :image, inverse_of: :depictions
  has_one :sqed_depiction, dependent: :destroy

  accepts_nested_attributes_for :image

  accepts_nested_attributes_for :sqed_depiction, allow_destroy: true

  # This seems OK given specs, though similar validations in other concerns have created headaches.
  validates_presence_of :depiction_object

end
