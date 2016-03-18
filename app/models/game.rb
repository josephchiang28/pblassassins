class Game < ActiveRecord::Base
  has_many :players
  has_many :assignments
  validates :name, presence: true, uniqueness: true
  validates :status, presence: true

  STATUS_INACTIVE = 'inactive'    # Game not active and assignments not generated
  STATUS_PENDING = 'pending'      # Game not active and assignments generated but not confirmed
  STATUS_ACTIVE = 'active'        # Game active and live
  STATUS_COMPLETED = 'completed'  # Game completed

  def is_inactive
    self.status == STATUS_INACTIVE
  end

  def is_pending
    self.status == STATUS_PENDING
  end

  def is_active
    self.status == STATUS_ACTIVE
  end

  def is_completed
    self.status == STATUS_COMPLETED
  end

end
