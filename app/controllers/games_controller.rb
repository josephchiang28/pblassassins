class GamesController < ApplicationController
  before_action :find_game_by_name
  before_action :verify_gamemaker_clearance, only: [:manage, :reassign_roles, :update_sponsor_points]

  def index
    @notes = @game.notes.order(created_at: :desc)
    if current_user
      @current_player = Player.find_by(user_id: current_user.id, game_id: @game.id)
    end
  end

  def index_json
    render json: {:game => {:status => @game.status, :public_enemy_mode => @game.public_enemy_mode ? 'on' : 'off'},
                  :news => @game.notes.order(created_at: :desc)}
  end

  def profile
    if current_user
      @current_player = Player.find_by(user_id: current_user.id, game_id: @game.id)
      if @current_player.nil?
        flash[:warning] = 'Error: Your profile for the game ' + params[:name] + ' does not exist.'
        redirect_to root_path
      end
    else
      flash[:warning] = 'Error: Please sign in to view your profile.'
      redirect_to root_path
    end
  end

  def roster
    players = @game.players
    gamemakers = players.where(role: Player::ROLE_GAMEMAKER).sort_by { |p| [p.committee, p.user.name]}
    assassins = players.where(role: [Player::ROLE_ASSASSIN_LIVE, Player::ROLE_ASSASSIN_DEAD]).sort_by { |p| [p.committee, p.user.name]}
    spectators = players.where(role: Player::ROLE_SPECTATOR).sort_by { |p| [p.committee, p.user.name]}
    @gamemakers_info = gamemakers.map { |p| { :committee => p.committee, :name => p.user.name } }
    @assassins_info = assassins.map { |p| { :committee => p.committee, :name => p.user.name } }
    @spectators_info = spectators.map { |p| { :committee => p.committee, :name => p.user.name } }
    if current_user
      @current_player = players.find_by(user_id: current_user.id)
    end
  end

  def roster_json
    roster
    render json: { :gamemakers => @gamemakers_info, :assassins => @assassins_info, :spectators => @spectators_info }
  end

  def leaderboard
    assassins_ranked = Player.where(game_id: @game.id, role: [Player::ROLE_ASSASSIN_LIVE, Player::ROLE_ASSASSIN_DEAD]).sort_by { |p| [-1 * (p.points || 0), p.is_assassin_live ? 0 : 1, p.committee, p.user.name]}
    @assassins_ranked_info = assassins_ranked.map { |a| { :committee => a.committee, :name => a.user.name, :points => a.points, :alive => a.is_assassin_live }}
    committee_points_hash = Hash.new
    assassins_ranked.each do |assassin|
      if committee_points_hash.key?(assassin.committee)
        committee_points_hash[assassin.committee][:points_total] += assassin.points
        committee_points_hash[assassin.committee][:members_count] += 1
      else
        committee_points_hash[assassin.committee] = {:points_total => assassin.points, :members_count => 1}
      end
    end
    committee_points_hash.each do |committee, points_and_count|
      points_and_count[:points_avg] = (points_and_count[:points_total].to_f / points_and_count[:members_count]).round(3)
      points_and_count.delete(:members_count)
    end
    committees_ranked_array = committee_points_hash.sort_by { |committee, points| [-1 * (points[:points_avg]), committee] }
    @committees_ranked_info = committees_ranked_array.map { |c, p| {:committee => c, :points_total => p[:points_total], :points_avg => p[:points_avg]} }
    if current_user
      @current_player = Player.find_by(user_id: current_user.id, game_id: @game.id)
    end
  end

  def leaderboard_json
    leaderboard
    render json: { :committees => @committees_ranked_info, :assassins => @assassins_ranked_info }
  end

  def manage
    @players = @game.players.sort_by { |p| [p.is_gamemaker ? 0 : p.is_assassin ? 1 : 2, p.committee, p.user.name]}
    if current_user
      @current_player = Player.find_by(user_id: current_user.id, game_id: @game.id)
    end
  end

  def set_public_enemy_mode
    public_enemy_mode_new = params[:public_enemy_mode].eql?('On') ? true : false
    if @game.public_enemy_mode != public_enemy_mode_new
      @game.update(public_enemy_mode: public_enemy_mode_new)
      flash[:success] = 'Success: Public enemy mode is now ' + (public_enemy_mode_new ? 'on.' : 'off.')
    else
      flash[:warning] = 'Public enemy mode is same as before.'
    end
    if current_user
      @current_player = Player.find_by(user_id: current_user.id, game_id: @game.id)
    end
    redirect_to game_manage_path(name: @game.name)
  end

  def reassign_roles
    if @game.reassign_players_role(params[:players])
      flash[:success] = 'Success: Reassign players role successful'
    else
      flash[:warning] = 'Error: Reassign players role failed.'
    end
    if current_user
      @current_player = Player.find_by(user_id: current_user.id, game_id: @game.id)
    end
    redirect_to game_manage_path(name: @game.name)
  end

  def history
    if current_user
      @current_player = Player.find_by(user_id: current_user.id, game_id: @game.id)
    end
    history_assignments_all = Assignment.where(game_id: @game.id, status: [Assignment::STATUS_COMPLETED, Assignment::STATUS_BACKFIRED, Assignment::STATUS_EXECUTED]).order(time_deactivated: :desc)
    @history_info_all = Array.new
    @history_info_public = Array.new
    history_assignments_all.each do |assignment|
      if assignment.is_completed
        killer_name = Player.find(assignment.assassin_id).user.name
        victim_name = Player.find(assignment.target_id).user.name
        kill_type = Assignment::FORWARD_KILL_TEXT
      elsif assignment.is_backfired
        killer_name = Player.find(assignment.target_id).user.name
        victim_name = Player.find(assignment.assassin_id).user.name
        kill_type = Assignment::REVERSE_KILL_TEXT
      elsif assignment.is_executed
        killer_name = Player.find(assignment.assassin_id).user.name
        victim_name = Player.find(assignment.target_id).user.name
        kill_type = Assignment::PUBLIC_ENEMY_KILL_TEXT
      else
        next
      end
      time_deactivated_string = assignment.time_deactivated.to_s
      if @current_player and @current_player.is_gamemaker
        @history_info_all.push({:time_assassinated => time_deactivated_string, :killer_name => killer_name, :victim_name => victim_name, :kill_type => kill_type})
      end
      @history_info_public.push({:time_assassinated => time_deactivated_string, :victim_name => victim_name})
    end
    if @current_player and @current_player.is_assassin
      @history_info_self = Array.new
      history_assignments_self = history_assignments_all
        .where('(assassin_id = ? AND (status = ? OR status = ?)) OR (target_id = ? AND status = ?)',
               @current_player.id, Assignment::STATUS_COMPLETED, Assignment::STATUS_EXECUTED, @current_player.id, Assignment::STATUS_BACKFIRED)
        .order(time_deactivated: :desc)
      history_assignments_self.each do |assignment|
        if assignment.is_completed
          @history_info_self.push({:time_assassinated => assignment.time_deactivated.to_s, :victim_name => Player.find(assignment.target_id).user.name, :kill_type => Assignment::FORWARD_KILL_TEXT})
        elsif assignment.is_backfired
          @history_info_self.push({:time_assassinated => assignment.time_deactivated.to_s, :victim_name => Player.find(assignment.assassin_id).user.name, :kill_type => Assignment::REVERSE_KILL_TEXT})
        elsif assignment.is_executed
          @history_info_self.push({:time_assassinated => assignment.time_deactivated.to_s, :victim_name => Player.find(assignment.target_id).user.name, :kill_type => Assignment::PUBLIC_ENEMY_KILL_TEXT})
        end
      end

      @deaths_info = Array.new
      death_assignments = history_assignments_all
        .where('(assassin_id = ? AND status = ?) OR (target_id = ? AND (status = ? OR status = ?))',
               @current_player.id, Assignment::STATUS_BACKFIRED, @current_player.id, Assignment::STATUS_COMPLETED, Assignment::STATUS_EXECUTED)
        .order(time_deactivated: :desc)
      death_assignments.each do |assignment|
        if assignment.is_completed
          @deaths_info.push({:time_assassinated => assignment.time_deactivated.to_s, :killer_name => Player.find(assignment.assassin_id).user.name, :kill_type => Assignment::FORWARD_KILL_TEXT})
        elsif assignment.is_backfired
          @deaths_info.push({:time_assassinated => assignment.time_deactivated.to_s, :killer_name => Player.find(assignment.target_id).user.name, :kill_type => Assignment::REVERSE_KILL_TEXT})
        elsif assignment.is_executed
          @deaths_info.push({:time_assassinated => assignment.time_deactivated.to_s, :killer_name => Player.find(assignment.assassin_id).user.name, :kill_type => Assignment::PUBLIC_ENEMY_KILL_TEXT})
        end
      end
    end
  end

  def history_json
    history
    render json: {:history_info_public => @history_info_public}
  end

  def sponsors
    @sponsors = @game.players.where(role: [Player::ROLE_GAMEMAKER, Player::ROLE_ASSASSIN_DEAD]).sort_by { |p| [-1 * p.sponsor_points, p.user.name]}
    if current_user
      @current_player = Player.find_by(user_id: current_user.id, game_id: @game.id)
    end
  end

  def sponsors_json
    sponsors
    render json: @sponsors.map { |s| {:name => s.user.name, :sponsor_points => s.sponsor_points} }
  end
  
  def update_sponsor_points
    begin
      sponsor = Player.find(params[:player_id])
    rescue ActiveRecord::RecordNotFound
      flash[:warning] = 'Error: Sponsor not found'
    end
    new_points = params[:new_points].to_i
    if new_points >= 0
      if sponsor.update_sponsor_points(new_points)
        flash[:success] = 'Sponsor points successfully updated!'
      else
        flash[:warning] = 'Ooops, an error occurred. Sponsor points not updated.'
      end
    else
      flash[:warning] = 'Error: Sponsor points must be positive.'
    end
    redirect_to game_sponsors_path(@game.name)
  end

  def rules
    if current_user
      @current_player = Player.find_by(user_id: current_user.id, game_id: @game.id)
    end
  end

  private

  def find_game_by_name
    begin
      @game = Game.find_by!(name: params[:name])
    rescue ActiveRecord::RecordNotFound => e
      flash[:warning] = 'Error: The game "' + params[:name] + '" does not exist.'
      redirect_to root_path
    end
  end

  def verify_gamemaker_clearance
    has_gamemaker_clearance = false
    if current_user
      @gamemaker = Player.find_by(user_id: current_user.id, game_id: @game.id)
      if @gamemaker and @gamemaker.is_gamemaker
        has_gamemaker_clearance = true
      end
    end
    if not has_gamemaker_clearance
      flash[:warning] = 'Error: You do not have the gamemaker clearance to view the page or perform the action.'
      redirect_to root_path
    end
  end
end