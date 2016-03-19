class Assignment < ActiveRecord::Base
  belongs_to :game
  validates :game_id, :assassin_id, :target_id, :status, presence: true

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

  # Generates a directed ring (list) of assassins
  def self.generate_ring(players)
    # TODO: Implement better generation algorithm
    ring = players.shuffle
    return ring
  end

  # Verifies if all players in ring are alive
  def self.verify_ring(ring)
    if ring.length < 2 # Should this be 2 or 3?
      return false
    end
    ring.each do |player|
      if not player.alive?
        return false
      end
    end
    return true
  end

  # Creates assignment rows in db
  # Returns boolean of whether all assignments are successfully created
  def self.create_assignments_from_ring(ring)
    if not verify_ring(ring)
      return false
    end
    game = Game.find(ring[0].game_id)
    Assignment.transaction do
      begin
        for i in 0..ring.length-1
          player = ring[i]
          player.update(killcode: SecureRandom.base64(5)) # Should killcode be regenerated?
          target_id = ring[(i + 1) % ring.length].id # Target is next in ring, loops back to first if current player is last in ring
          game.assignments.create(assassin_id: player.id, target_id: target_id, status: Assignment::STATUS_INACTIVE)
        end
      rescue ActiveRecord::RecordInvalid => exception
        p exception.message
        return false
      end
    end
    return true
  end

  # Generates inactive assignments only. Does not activate them.
  def self.generate_assignments(game_id, type)
    @game = Game.find(game_id)
    if type.eql?('all')
      @assassins = Player.where(game_id: @game.id, role: Player::ROLE_ASSASSIN)
    elsif type.equl?('active_only')
      @assassins = Player.where(game_id: @game.id, role: Player::ROLE_ASSASSIN, alive: true)
    end
    ring = generate_ring(@assassins)
    if create_assignments_from_ring(ring)
      # do sth
      # flash[:success] = 'Assignments successfully generated!'
    else
      # do sth
      # flash[:warning] = 'Assignments not generated due to some error.'
    end
  end

end
