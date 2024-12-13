class Company < ApplicationRecord
  has_many :users
  has_many :orders
  has_many :machines

  validates :name, presence: true, uniqueness: true
end
