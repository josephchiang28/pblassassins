class Player < ActiveRecord::Base
  belongs_to :user
  belongs_to :game
  validates :user_id, :game_id, :committee, :role, :points, :sponsor_points, presence: true
  validates :user_id, uniqueness: {scope: :game_id}
  validates :alive, :inclusion => {:in => [true, false]}

  ROLE_GAMEMAKER = 'gamemaker' # Gamemaker and owner of the game
  ROLE_ASSASSIN = 'assassin'   # Assassin player
  ROLE_SPECTATOR = 'spectator' # Spectator, not participating

  def is_gamemaker
    self.role.eql?(ROLE_GAMEMAKER)
  end

  def is_assassin
    self.role.eql?(ROLE_ASSASSIN)
  end
  
  def update_points(new_points)
    new_points_int = Integer(new_points)
    if new_points_int >= 0
      Player.transaction do
        begin
          self.update!(sponsor_points: new_points_int)
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
        end
      end
    end
  end

  def is_spectator
    self.role.eql?(ROLE_SPECTATOR)
  end

end
