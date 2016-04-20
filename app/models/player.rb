class Player < ActiveRecord::Base
  belongs_to :user
  belongs_to :game
  validates :user_id, :game_id, :committee, :role, :points, :sponsor_points, presence: true
  validates :user_id, uniqueness: {scope: :game_id}

  ROLE_GAMEMAKER = 'gamemaker'         # Gamemaker and owner of the game
  ROLE_ASSASSIN_LIVE = 'assassin_live' # Live assassin player
  ROLE_ASSASSIN_DEAD = 'assassin_dead' # Dead assassin player
  ROLE_SPECTATOR = 'spectator'         # Spectator, not participating
  ROLES = [ROLE_GAMEMAKER, ROLE_ASSASSIN_LIVE, ROLE_ASSASSIN_DEAD, ROLE_SPECTATOR]

  def is_gamemaker
    self.role.eql?(ROLE_GAMEMAKER)
  end

  def is_assassin_live
    self.role.eql?(ROLE_ASSASSIN_LIVE)
  end

  def is_assassin_dead
    self.role.eql?(ROLE_ASSASSIN_DEAD)
  end

  def is_assassin
    self.is_assassin_live or self.is_assassin_dead
  end

  def is_spectator
    self.role.eql?(ROLE_SPECTATOR)
  end

  # Returns true if successfully updates sponsor points, false otherwise
  def update_sponsor_points(new_points)
    if new_points >= 0
      begin
        self.update!(sponsor_points: new_points)
      rescue Exception => e
        p 'ERROR: CANNOT UPDATE SPONSOR POINTS! ' +  e.message
        return false
      end
    else
      return false
    end
    true
  end

end
