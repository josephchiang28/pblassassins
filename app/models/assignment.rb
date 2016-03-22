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
  FORWARD_KILL_POINTS = 1
  REVERSE_KILL_POINTS = 2

  def is_inactive
    self.status.eql?(STATUS_INACTIVE)
  end

  def is_active
    self.status.eql?(STATUS_ACTIVE)
  end

  def is_failed
    self.status.eql?(STATUS_FAILED)
  end

  def is_stolen
    self.status.eql?(STATUS_STOLEN)
  end

  def is_completed
    self.status.eql?(STATUS_COMPLETED)
  end

  def is_backfired
    self.status.eql?(STATUS_BACKFIRED)
  end

  def is_discarded
    self.status.eql?(STATUS_DISCARDED)
  end

  # Generates a directed ring (list) of assassins
  def self.generate_ring(players)
    # TODO: Implement better generation algorithm
    ring = players.shuffle
    return ring
  end

  # Verifies if all players in ring are alive and in same game
  def self.verify_ring(ring)
    if ring.length < 2 # Should this be 2 or 3?
      return false
    end
    game_id = ring[0].game_id
    ring.each do |player|
      if not player.alive? or player.game_id != game_id
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
          player.update!(killcode: SecureRandom.base64(5)) # Should killcode be regenerated?
          target_id = ring[(i + 1) % ring.length].id # Target is next in ring, loops back to first if current player is last in ring
          game.assignments.create!(assassin_id: player.id, target_id: target_id, status: STATUS_INACTIVE)
        end
      rescue ActiveRecord::RecordInvalid => exception
        p 'ERROR: CREATE_ASSIGNMENTS_FROM_RING FAILED! ' + exception.message
        return false
      end
    end
    return true
  end

  def self.get_ring_from_assignments(assignments)
    # Check for assignment validity? Like length and if all belongs to same game
    if assignments.nil? or assignments.empty?
      return Array.new
    end
    ring = Array.new
    players = Player.where(game_id: assignments.first.game_id)
    curr_assignment = assignments.first
    curr_player = players.find(curr_assignment.assassin_id)
    if curr_player.nil?
      return nil
    end
    ring.append(curr_player)
    for i in 1..assignments.length - 1
      curr_assignment = assignments.where(assassin_id: curr_assignment.target_id).first
      if curr_assignment.nil?
        return nil
      else
        curr_player = players.find(curr_assignment.assassin_id)
        if curr_player.nil?
          return false
        end
        ring.append(curr_player)
      end
    end
    return ring
  end

  # Generates inactive assignments only. Does not activate them.
  def self.generate_assignments(game_id, type)
    @game = Game.find(game_id)
    if type.eql?('all')
      @assassins = Player.where(game_id: @game.id, role: Player::ROLE_ASSASSIN)
      @game.update(status: Game::STATUS_PENDING)
    elsif type.eql?('active_only')
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

  def self.discard_old_and_activate_new_assignments(game_id)
    assignments_old = Assignment.where(game_id: game_id, status: STATUS_ACTIVE)
    assignments_new = Assignment.where(game_id: game_id, status: STATUS_INACTIVE)
    Assignment.transaction do
      begin
        assignments_old.update_all(status: STATUS_DISCARDED, time_deactivated: Time.now)
        assignments_new.update_all(status: STATUS_ACTIVE, time_activated: Time.now)
        Game.find(game_id).update(status: Game::STATUS_ACTIVE)
      rescue ActiveRecord::RecordInvalid => exception
        p 'ERROR: ACTIVATE ASSIGNMENTS FAILED! ' + exception.message
      end
    end
  end

  def self.destroy_inactive_assignments(game_id)
    Assignment.where(game_id: game_id, status: Assignment::STATUS_INACTIVE).destroy_all
  end

  def self.register_kill(game, assassin, victim_email, killcode, is_reverse_kill)
    game_assignments = game.assignments
    if is_reverse_kill
      assignment = game_assignments.where(target_id: assassin.id, status: STATUS_ACTIVE).first # Check if there's only 1 such assignment?
      victim = Player.find(assignment.assassin_id) # Check if victim is found?
    else
      assignment = game_assignments.where(assassin_id: assassin.id, status: STATUS_ACTIVE).first # Check if there's only 1 such assignment?
      victim = Player.find(assignment.target_id) # Check if victim is found?
    end

    if victim.user.email.eql?(victim_email) and killcode.eql?(victim.killcode)
      # Update players and game status
      Assignment.transaction do
        begin
          victim.update!(alive: false)
          if is_reverse_kill
            assignment.update!(status: STATUS_BACKFIRED, time_deactivated: Time.now)
            assignment_stolen = game_assignments.where(target_id: victim.id, status: STATUS_ACTIVE).first
            assignment_stolen.update!(status: STATUS_STOLEN, time_deactivated: Time.now)
            game_assignments.create!(assassin_id: assignment_stolen.assassin_id, target_id: assassin.id, status: STATUS_ACTIVE, time_activated: Time.now)
            assassin.increment!(:points, by = REVERSE_KILL_POINTS)
          else
            assignment.update!(status: STATUS_COMPLETED, time_deactivated: Time.now)
            assignment_failed = game_assignments.where(assassin_id: victim.id, status: STATUS_ACTIVE).first
            assignment_failed.update!(status: STATUS_FAILED, time_deactivated: Time.now)
            game_assignments.create!(assassin_id: assassin.id, target_id: assignment_failed.target_id, status: STATUS_ACTIVE, time_activated: Time.now)
            assassin.increment!(:points, by = FORWARD_KILL_POINTS)
          end
        rescue ActiveRecord::RecordInvalid => exception
          p 'ERROR: REGISTER KILL FAILED! ' + exception.message
          return false
        end
      end
    else
      return false
    end
    if game.players.where(role: Player::ROLE_ASSASSIN, alive: true).length == 1
      game.complete_game
    end
    return true
  end

end
