require 'rails_helper'
describe Lot, :type => :model do
  let(:lot) { FactoryGirl.build(:lot) }

  context "validation" do
    before(:each) {
      lot.valid?
    }

    context "before validation" do
      specify "total must be > 1" do 
        expect(lot.errors.keys).to include(:total)
      end
    end
  end

  context "concerns" do
    it_behaves_like "containable"
    it_behaves_like "identifiable"
  end

end


