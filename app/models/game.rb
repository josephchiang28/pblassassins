class Game < ActiveRecord::Base
  has_many :players
  has_many :assignments
  validates :name, :status, presence: true

end
