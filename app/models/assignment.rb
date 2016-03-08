class Assignment < ActiveRecord::Base
  belongs_to :game
  validates :game_id, :assassin_id_id, :target_id, :status, presence: true

end
