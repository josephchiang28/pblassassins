class Assignment < ActiveRecord::Base
  belongs_to :game
  validates :game_id, :assassin_id_id, :target_id, :status, presence: true

  STATUS_INACTIVE = 'inactive'   # Assignment generated but not confirmed and activated
  STATUS_ACTIVE = 'active'       # Assignment confirmed and activated
  STATUS_FAILED = 'failed'       # Got killed before completing assignment
  STATUS_STOLEN = 'stolen'       # Target got reverse killed
  STATUS_COMPLETED = 'completed' # Successful completion of assignment
  STATUS_BACKFIRED = 'backfired' # Got reverse killed
  STATUS_DISCARDED = 'discarded' # Discarded, target reassigned manually

  def is_inactive
    self.status == STATUS_INACTIVE
  end

  def is_active
    self.status == STATUS_ACTIVE
  end

  def is_failed
    self.status == STATUS_FAILED
  end

  def is_stolen
    self.status == STATUS_STOLEN
  end

  def is_completed
    self.status == STATUS_COMPLETED
  end

  def is_backfired
    self.status == STATUS_BACKFIRED
  end

  def is_discarded
    self.status == STATUS_DISCARDED
  end

end
