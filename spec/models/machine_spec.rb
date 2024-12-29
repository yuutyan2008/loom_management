require 'rails_helper'

RSpec.describe Machine, type: :model do
  describe 'validations' do
    subject { create(:machine) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:machine_type_id) }
    it do
      is_expected.to validate_uniqueness_of(:name)
        .scoped_to(:company_id)
        .with_message("は同じ会社内で一意である必要があります")
    end
  end
end
