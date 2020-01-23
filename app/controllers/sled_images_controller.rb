class SledImagesController < ApplicationController
  before_action :set_sled_image, only: [:update, :create, :destroy]

  # POST /sled_images.json
  def create
    @sled_image = SledImage.new(sled_image_params)
    respond_to do |format|
      if @sled_image.save
        format.json { render :show, status: :created, location: @sled_image }
      else
        format.json { render json: @sled_image.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sled_images/1.json
  def update
    respond_to do |format|
      if @sled_image.update(sled_image_params)
        format.json { render :show, status: :ok, location: @sled_image }
      else
        format.json { render json: @sled_image.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sled_images/1.json
  def destroy
    @sled_image.nuke = params[:nuke]
    @sled_image.destroy
    respond_to do |format|
      format.html { redirect_to sled_images_url, notice: 'Sled image was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_sled_image
    @sled_image = SledImage.find(params[:id])
  end

  def sled_image_params
    params.permit(
      :image_id, :metadata, :object_layout,
      :step_identifier_on
    ).merge(
      collection_object_params: collection_object_params
    )
  end

  def collection_object_params
    params[:collection_object]&.permit(
      :collecting_event_id,
      identifiers_attributes: [:namespace_id, :identifier, :type],
      notes_attributes: [:text], 
      tags_attributes: [:id, :_destroy, :keyword_id],
      data_attributes_attributes: [ :id, :_destroy, :controlled_vocabulary_term_id, :type, :value ], # not implemented
      taxon_determinations_attributes: [
        :id, :_destroy, :otu_id, :year_made, :month_made, :day_made, 
        roles_attributes: [
          :id, :_destroy, :type, :person_id, :position,
          person_attributes: [:last_name, :first_name, :suffix, :prefix]
        ]
      ]
    ) || {}
  end

end
