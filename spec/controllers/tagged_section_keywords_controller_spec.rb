require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe TaggedSectionKeywordsController, :type => :controller do
  before(:each) {
    sign_in
  }

  # This should return the minimal set of attributes required to create a valid
  # TaggedSectionKeyword. As you add validations to TaggedSectionKeyword, be sure to
  # adjust the attributes here as well.
  #
  let(:other_keyword) { FactoryBot.create(:valid_keyword, name: 'Other keyword', definition: 'Not that one, the longer one.') }
  let(:valid_attributes) { strip_housekeeping_attributes(FactoryBot.build(:valid_tagged_section_keyword).attributes) }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # TaggedSectionKeywordsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  before {
    request.env['HTTP_REFERER'] = list_otus_path # logical example
  }

  describe "POST create" do
    describe "with valid params" do
      it "creates a new TaggedSectionKeyword" do
        expect {
          post :create, params: {tagged_section_keyword: valid_attributes}, session: valid_session
        }.to change(TaggedSectionKeyword, :count).by(1)
      end

      it "assigns a newly created tagged_section_keyword as @tagged_section_keyword" do
        post :create, params: {tagged_section_keyword: valid_attributes}, session: valid_session
        expect(assigns(:tagged_section_keyword)).to be_a(TaggedSectionKeyword)
        expect(assigns(:tagged_section_keyword)).to be_persisted
      end

      it "redirects to :back" do
        post :create, params: {tagged_section_keyword: valid_attributes}, session: valid_session
        expect(response).to redirect_to(list_otus_path)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved tagged_section_keyword as @tagged_section_keyword" do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(TaggedSectionKeyword).to receive(:save).and_return(false)
        post :create, params: {tagged_section_keyword: {invalid: 'parms'}}, session: valid_session
        expect(assigns(:tagged_section_keyword)).to be_a_new(TaggedSectionKeyword)
      end

      it "re-renders the :back template" do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(TaggedSectionKeyword).to receive(:save).and_return(false)
        post :create, params: {tagged_section_keyword: {invalid: 'parms'}}, session: valid_session
        expect(response).to redirect_to(list_otus_path)
      end
    end
  end

  describe 'PUT update' do
    describe 'with valid params' do
      it 'updates the requested tagged_section_keyword' do
        tagged_section_keyword = TaggedSectionKeyword.create! valid_attributes
        # Assuming there are no other tagged_section_keywords in the database, this
        # specifies that the TaggedSectionKeyword created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        update_params = ActionController::Parameters.new({keyword_id: other_keyword.to_param}).permit(:keyword_id)
        expect_any_instance_of(TaggedSectionKeyword).to receive(:update).with(update_params)
        put :update, params: {:id => tagged_section_keyword.to_param, tagged_section_keyword: {keyword_id: other_keyword.to_param}}, session: valid_session
      end

      it "assigns the requested tagged_section_keyword as @tagged_section_keyword" do
        tagged_section_keyword = TaggedSectionKeyword.create! valid_attributes
        put :update, params: {id: tagged_section_keyword.to_param, tagged_section_keyword: valid_attributes}, session: valid_session
        expect(assigns(:tagged_section_keyword)).to eq(tagged_section_keyword)
      end

      it "redirects to :back" do
        tagged_section_keyword = TaggedSectionKeyword.create! valid_attributes
        put :update, params: {id: tagged_section_keyword.to_param, tagged_section_keyword: valid_attributes}, session: valid_session
        expect(response).to redirect_to(list_otus_path)
      end
    end

    describe "with invalid params" do
      it "assigns the tagged_section_keyword as @tagged_section_keyword" do
        tagged_section_keyword = TaggedSectionKeyword.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(TaggedSectionKeyword).to receive(:save).and_return(false)
        put :update, params: {id: tagged_section_keyword.to_param, tagged_section_keyword: {invalid: 'parms'}}, session: valid_session
        expect(assigns(:tagged_section_keyword)).to eq(tagged_section_keyword)
      end

      it "re-renders the :back template" do
        tagged_section_keyword = TaggedSectionKeyword.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(TaggedSectionKeyword).to receive(:save).and_return(false)
        put :update, params: {id: tagged_section_keyword.to_param, tagged_section_keyword: {invalid: 'parms'}}, session: valid_session
        expect(response).to redirect_to(list_otus_path)
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested tagged_section_keyword" do
      tagged_section_keyword = TaggedSectionKeyword.create! valid_attributes
      expect {
        delete :destroy, params: {id: tagged_section_keyword.to_param}, session: valid_session
      }.to change(TaggedSectionKeyword, :count).by(-1)
    end

    it "redirects to :back" do
      tagged_section_keyword = TaggedSectionKeyword.create! valid_attributes
      delete :destroy, params: {id: tagged_section_keyword.to_param}, session: valid_session
      expect(response).to redirect_to(list_otus_path)
    end
  end

end
