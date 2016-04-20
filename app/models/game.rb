class Game < ActiveRecord::Base
  has_many :players
  has_many :assignments
  has_many :notes
  validates :name, presence: true, uniqueness: true
  validates :status, presence: true

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
end
