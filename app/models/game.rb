class Game < ActiveRecord::Base
  has_many :players
  has_many :assignments
  has_many :notes
  validates :name, presence: true, uniqueness: true
  validates :status, presence: true
  validates :public_enemy_mode, :inclusion => {:in => [true, false]}

  STATUS_INACTIVE = 'inactive'    # Game not active and assignments not generated
  STATUS_PENDING = 'pending'      # Game not active and assignments generated but not confirmed
  STATUS_ACTIVE = 'active'        # Game active and live
  STATUS_COMPLETED = 'completed'  # Game completed

  def is_inactive
    self.status.eql?(STATUS_INACTIVE)
  end

  def is_pending
    self.status.eql?(STATUS_PENDING)
  end

  def is_active
    self.status.eql?(STATUS_ACTIVE)
  end

  def is_completed
    self.status.eql?(STATUS_COMPLETED)
  end

  def check_and_complete_game
    if self.players.where(role: Player::ROLE_ASSASSIN_LIVE).length == 1
      self.update(status: STATUS_COMPLETED)
    end
  end

  # Reassign players role. Return true if all reassignments successful, false otherwise.
  def reassign_players_role(players_id_role_hash)
    Game.transaction do
      begin
        players_id_role_hash.each do |id, role|
          player = Player.find(id)
          if Player::ROLES.include?(role) and not player.role.eql?(role)
            if player.is_assassin_live
              Assignment.discharge_assassin(player, role)
            elsif player.is_assassin_dead or player.is_gamemaker or player.is_spectator
              if role.eql?(Player::ROLE_ASSASSIN_LIVE)
                Assignment.enlist_assassin(player) # Role is updated to ROLE_ASSASSIN_LIVE in enlist_assassin method
              else
                player.update!(role: role)
              end
            end
          end
        end
      rescue Exception => e
        p 'ERROR: REASSIGN PLAYERS ROLE FAILED! ' + e.message
        return false
      end
    end
  end
end
