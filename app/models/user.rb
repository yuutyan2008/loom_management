class User < ApplicationRecord
  belongs_to :company

  has_secure_password

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, allow_blank: true
  validates :phone_number, presence: true, allow_blank: true
  # validates :company_id, presence: true
  validates :password, presence: true, length: { in: 6..20 }, if: :password_present?
  validates :password_confirmation, presence: true, if: :password_present?

  private
  # 条件付きvalidationの関数定義
  def password_present?
    password.present? || password_confirmation.present?
  end
end
