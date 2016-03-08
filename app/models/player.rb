class Player < ActiveRecord::Base
  belongs_to :user
  belongs_to :game
  belongs_to :committee
  validates :user_id, :game_id, :committee_id, :role, :alive, :points, presence: true

end
