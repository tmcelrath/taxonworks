class ControlledVocabularyTermsController < ApplicationController
  include DataControllerConfiguration

  before_action :require_sign_in_and_project_selection
  before_action :set_controlled_vocabulary_term, only: [:show, :edit, :update, :destroy]

  # GET /controlled_vocabulary_terms
  # GET /controlled_vocabulary_terms.json
  def index
    @controlled_vocabulary_terms = ControlledVocabularyTerm.all
  end

  # GET /controlled_vocabulary_terms/1
  # GET /controlled_vocabulary_terms/1.json
  def show
  end

  # GET /controlled_vocabulary_terms/new
  def new
    @controlled_vocabulary_term = ControlledVocabularyTerm.new
  end

  # GET /controlled_vocabulary_terms/1/edit
  def edit
  end

  # POST /controlled_vocabulary_terms
  # POST /controlled_vocabulary_terms.json
  def create
    @controlled_vocabulary_term = ControlledVocabularyTerm.new(controlled_vocabulary_term_params)



    respond_to do |format|
      if @controlled_vocabulary_term.save
        redirect_url = (request.env['HTTP_REFERER'].include?('controlled_vocabulary_terms/new') ? controlled_vocabulary_term_path(@controlled_vocabulary_term) : :back)
        format.html { redirect_to redirect_url, notice: 'Controlled vocabulary term was successfully created.' } # !! new behaviour to test
        format.json { render action: 'show', status: :created, location: @controlled_vocabulary_term.becomes(ControlledVocabularyTerm) }
      else
        format.html { 
          flash[:notice] = 'Controlled vocabulary term NOT successfully created.' 
          if redirect_url == :back 
            redirect_to :back 
          else
            render action: 'new'
          end
        }
        format.json { render json: @controlled_vocabulary_term.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /controlled_vocabulary_terms/1
  # PATCH/PUT /controlled_vocabulary_terms/1.json
  def update
    respond_to do |format|
      if @controlled_vocabulary_term.update(controlled_vocabulary_term_params)
        format.html { redirect_to @controlled_vocabulary_term.becomes(ControlledVocabularyTerm), notice: 'Controlled vocabulary term was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @controlled_vocabulary_term.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /controlled_vocabulary_terms/1
  # DELETE /controlled_vocabulary_terms/1.json
  def destroy
    redirect_url = (request.env['HTTP_REFERER'].include?(controlled_vocabulary_term_path(@controlled_vocabulary_term.becomes(ControlledVocabularyTerm))) ? controlled_vocabulary_terms_url : :back)
    @controlled_vocabulary_term.destroy
    respond_to do |format|
      format.html { redirect_to redirect_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_controlled_vocabulary_term
      @controlled_vocabulary_term = ControlledVocabularyTerm.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def controlled_vocabulary_term_params
      params.require(:controlled_vocabulary_term).permit(:type, :name, :definition, :created_by_id, :updated_by_id, :project_id)
    end
end
