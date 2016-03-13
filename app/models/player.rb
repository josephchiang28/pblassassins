class Player < ActiveRecord::Base
  belongs_to :user
  belongs_to :game
  validates :user_id, :game_id, :committee, :role, :alive, :points, presence: true

  ROLE_GAMEMAKER = 'gamemaker' # Gamemaker and owner of the game
  ROLE_ASSASSIN = 'assassin'   # Assassin player

  def is_gamemaker
    self.role == ROLE_GAMEMAKER
  end

  def is_assassin
    self.role == ROLE_ASSASSIN
  end

end
