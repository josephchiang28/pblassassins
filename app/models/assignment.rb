class Assignment < ActiveRecord::Base
  belongs_to :game
  validates :game_id, :assassin_id, :target_id, :status, presence: true

  STATUS_INACTIVE = 'inactive'         # Assignment generated but not confirmed and activated
  STATUS_ACTIVE = 'active'             # Assignment confirmed and activated
  STATUS_FAILED = 'failed'             # Assassin got forward killed or killed as a public enemy before completing assignment
  STATUS_STOLEN = 'stolen'             # Target got reverse killed or killed as a public enemy not by the assassin
  STATUS_COMPLETED = 'completed'       # Assassin successfully killed target
  STATUS_BACKFIRED = 'backfired'       # Assassin got reverse killed by target
  STATUS_DISCARDED = 'discarded'       # Target reassigned manually by gamemaker
  STATUS_DISCHARGED = 'discharged'     # Assassin is manually killed by gamemaker
  STATUS_EXECUTED = 'executed'         # Assignment created to record a public enemy kill
  FORWARD_KILL_TEXT = 'Forward Kill'
  REVERSE_KILL_TEXT = 'Reverse Kill'
  PUBLIC_ENEMY_KILL_TEXT = 'Public Enemy Kill'
  FORWARD_KILL_POINTS = 1
  REVERSE_KILL_POINTS = 2
  PUBLIC_ENEMY_KILL_POINTS = 1


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

  def is_discharged
    self.status.eql?(STATUS_DISCHARGED)
  end

  def is_executed
    self.status.eql?(STATUS_EXECUTED)
  end

  # Generates a directed ring (active record list) of assassins
  def self.generate_ring(assassins, blacklist_size = 3)
    ring = Array.new
    committee_blacklist = Array.new # Using array instead of queue for SQL query
    num_assassins = assassins.length
    while ring.length < num_assassins
      ring_ids = ring.map { |x| x.id }
      assassins_eligible = assassins.where.not(id: ring_ids, committee: committee_blacklist)
      while assassins_eligible.empty?
        # In the case that assassins left to be assigned are in a committee in the blacklist
        assassins_eligible = assassins.where.not(id: ring_ids, committee: committee_blacklist)
        committee_blacklist.delete_at(0)
      end
      assassin_chosen = assassins_eligible.sample
      ring.append(assassin_chosen)
      committee_blacklist.append(assassin_chosen.committee)
      while committee_blacklist.length > blacklist_size
        committee_blacklist.delete_at(0)
      end
    end
    return ring
  end

  # Verifies if all players in ring are alive and in same game
  def self.verify_ring(ring)
    if ring.length < 2 # Should this be 2 or 3?
      return false
    end
    game_id = ring[0].game_id
    ring.each do |player|
      if player.is_assassin_dead or player.game_id != game_id
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
      curr_assignment = assignments.find_by(assassin_id: curr_assignment.target_id)
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
      @assassins = Player.where(game_id: @game.id, role: [Player::ROLE_ASSASSIN_LIVE, Player::ROLE_ASSASSIN_DEAD])
    elsif type.eql?('active_only')
      @assassins = Player.where(game_id: @game.id, role: Player::ROLE_ASSASSIN_LIVE)
    end
    Assignment.transaction do
      begin
        Assignment.where(game_id: @game.id, status: STATUS_INACTIVE).destroy_all
        ring = generate_ring(@assassins)
        if create_assignments_from_ring(ring)
          if type.eql?('all')
            @game.update(status: Game::STATUS_PENDING)
          end
          # do sth
          # flash[:success] = 'Assignments successfully generated!'
        else
          # do sth
          # flash[:warning] = 'Assignments not generated due to some error.'
        end
      rescue Exception => exception
        p 'ERROR: GENERATE ASSIGNMENT FAILED! ' + exception.message
      end
    end
  end

  # Verify if inactive assignments are still valid based on active assignments
  def self.verify_inactive_assignments(assignments_active, assignments_inactive)
    (Set.new(assignments_active.pluck(:assassin_id)) == Set.new(assignments_inactive.pluck(:assassin_id)) and
        Set.new(assignments_active.pluck(:target_id)) == Set.new(assignments_inactive.pluck(:target_id)))
  end

  def self.discard_old_and_activate_new_assignments(game_id)
    assignments_old = Assignment.where(game_id: game_id, status: STATUS_ACTIVE)
    assignments_new = Assignment.where(game_id: game_id, status: STATUS_INACTIVE)
    Assignment.transaction do
      begin
        assignments_old.update_all(status: STATUS_DISCARDED, time_deactivated: Time.current)
        assignments_new.update_all(status: STATUS_ACTIVE, time_activated: Time.current)
        Game.find(game_id).update(status: Game::STATUS_ACTIVE)
      rescue ActiveRecord::RecordInvalid => exception
        p 'ERROR: ACTIVATE ASSIGNMENTS FAILED! ' + exception.message
      end
    end
  end

  def self.destroy_inactive_assignments(game_id)
    Assignment.where(game_id: game_id, status: STATUS_INACTIVE).destroy_all
  end

  def self.register_kill(assassin, victim_name, killcode, kill_type)
    game = assassin.game
    victim_name = victim_name.strip
    killcode = killcode.strip
    game_assignments = game.assignments
    Assignment.transaction do
      begin
        if kill_type.eql?(FORWARD_KILL_TEXT)
          assignment = game_assignments.find_by!(assassin_id: assassin.id, status: STATUS_ACTIVE) # Check if there's only 1 such assignment?
          victim = Player.find(assignment.target_id)
          if victim.user.name.eql?(victim_name) and victim.killcode.eql?(killcode)
            assignment.update!(status: STATUS_COMPLETED, time_deactivated: Time.current)
            assignment_failed = game_assignments.find_by!(assassin_id: victim.id, status: STATUS_ACTIVE)
            assignment_failed.update!(status: STATUS_FAILED, time_deactivated: Time.current)
            game_assignments.create!(assassin_id: assassin.id, target_id: assignment_failed.target_id, status: STATUS_ACTIVE, time_activated: Time.current)
            victim.update!(role: Player::ROLE_ASSASSIN_DEAD)
            assassin.increment!(:points, by = FORWARD_KILL_POINTS)
          else
            return false
          end
        elsif kill_type.eql?(REVERSE_KILL_TEXT)
          assignment = game_assignments.find_by!(target_id: assassin.id, status: STATUS_ACTIVE) # Check if there's only 1 such assignment?
          victim = Player.find(assignment.assassin_id)
          if victim.user.name.eql?(victim_name) and victim.killcode.eql?(killcode)
            assignment.update!(status: STATUS_BACKFIRED, time_deactivated: Time.current)
            assignment_stolen = game_assignments.find_by!(target_id: victim.id, status: STATUS_ACTIVE)
            assignment_stolen.update!(status: STATUS_STOLEN, time_deactivated: Time.current)
            game_assignments.create!(assassin_id: assignment_stolen.assassin_id, target_id: assassin.id, status: STATUS_ACTIVE, time_activated: Time.current)
            victim.update!(role: Player::ROLE_ASSASSIN_DEAD)
            assassin.increment!(:points, by = REVERSE_KILL_POINTS)
          else
            return false
          end
        elsif kill_type.eql?(PUBLIC_ENEMY_KILL_TEXT)
          if game.public_enemy_mode?
            # Assuming no killcode in a game will be identical, need to test all possible victims since multiple players can have the same name
            # Kills the first killcode match
            possible_users = User.where(name: victim_name).map { |user| user.players.find_by(game_id: game.id) }
            possible_users.each do |victim|
              if victim and victim.is_public_enemy and victim.killcode.eql?(killcode)
                assignment_failed = game.assignments.find_by!(assassin_id: victim.id, status: STATUS_ACTIVE)
                assignment_failed.update!(status: STATUS_FAILED, time_deactivated: Time.current)
                assignment_stolen = game_assignments.find_by!(target_id: victim.id, status: STATUS_ACTIVE)
                assignment_stolen.update!(status: STATUS_STOLEN, time_deactivated: Time.current)
                game_assignments.create!(assassin_id: assignment_stolen.assassin_id, target_id: assignment_failed.target_id, status: STATUS_ACTIVE, time_activated: Time.current)
                game_assignments.create!(assassin_id: assassin.id, target_id: victim.id, status: STATUS_EXECUTED , time_activated: Time.current, time_deactivated: Time.current)
                victim.update!(role: Player::ROLE_ASSASSIN_DEAD)
                assassin.increment!(:points, by = PUBLIC_ENEMY_KILL_POINTS)
                game.check_and_complete_game
                return true
              end
            end
            # Killcode did not match any player
            return false
          else
            p 'ERROR: PUBLIC ENEMY ATTEMPT WHILE NOT IN PUBLIC ENEMY MODE.'
            return false
          end
        else
          p 'ERROR: INVALID KILL TYPE.'
          return false
        end
      rescue ActiveRecord::RecordInvalid => exception
        p 'ERROR: REGISTER KILL FAILED! ' + exception.message
        return false
      end
    end
    game.check_and_complete_game
    return true
  end

  # Assassin manually killed by gamemaker. No points are awarded.
  def self.discharge_assassin(assassin, new_role=Player::ROLE_ASSASSIN_DEAD)
    if new_role.eql?(Player::ROLE_ASSASSIN_LIVE) or not assassin.is_assassin_live
      p 'ERROR: DISCHARGE ASSASSIN FAILED! Player must be a live assassin and new role must not be ROLE_ASSASSIN_LIVE.'
      return false
    end
    game = assassin.game
    game_assignments = game.assignments
    Assignment.transaction do
      begin
        assassin.update!(role: new_role)
        assignment_discharged = game_assignments.find_by!(assassin_id: assassin.id, status: STATUS_ACTIVE)
        assignment_discharged.update!(status: STATUS_DISCHARGED, time_deactivated: Time.current)
        assignment_discarded = game_assignments.find_by!(target_id: assassin.id, status: STATUS_ACTIVE)
        assignment_discarded.update!(status: STATUS_DISCARDED, time_deactivated: Time.current)
        game_assignments.create!(assassin_id: assignment_discarded.assassin_id, target_id: assignment_discharged.target_id, status: STATUS_ACTIVE, time_activated: Time.current)
      rescue Exception => e
        p 'ERROR: DISCHARGE ASSASSIN FAILED! ' + e.message
        return false
      end
    end
    game.check_and_complete_game
    true
  end

  # Change the player's role to ROLE_ASSASSIN_LIVE. To actually add the assassin into the assignment ring, gamemakers will have to do so in manual reassign.
  def self.enlist_assassin(assassin)
    if assassin.is_assassin_live
      p 'ERROR: ENLIST ASSASSIN FAILED! Player must not be a live assassin.'
      return false
    end
    begin
      assassin.update!(role: Player::ROLE_ASSASSIN_LIVE)
    rescue Exception => e
      p 'ERROR: ENLIST ASSASSIN FAILED! ' + exception.message
      return false
    end
    true
  end

end
