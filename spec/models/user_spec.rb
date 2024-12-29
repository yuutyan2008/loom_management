require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { create(:user) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value("").for(:email) } # allow_blank validation
    it { is_expected.to validate_presence_of(:phone_number) }
    it { is_expected.to allow_value("").for(:phone_number) } # allow_blank validation
    it { is_expected.to validate_presence_of(:company_id) }
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to validate_length_of(:password).is_at_least(6) }
    it { is_expected.to validate_presence_of(:password_confirmation) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:company) }
  end
end

