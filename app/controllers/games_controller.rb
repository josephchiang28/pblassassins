class GamesController < ApplicationController
  before_action :find_game_by_name
  before_action :verify_gamemaker_clearance, only: [:update_sponsor_points]

  def index
    @notes = @game.notes.order(created_at: :desc)
    if current_user
      @current_player = Player.find_by(user_id: current_user.id, game_id: @game.id)
    end
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
    @gamemakers = players.where(role: Player::ROLE_GAMEMAKER).sort_by { |p| [p.committee, p.user.name]}
    @assassins = players.where(role: Player::ROLE_ASSASSIN).sort_by { |p| [p.committee, p.user.name]}
    @spectators = players.where(role: Player::ROLE_SPECTATOR).sort_by { |p| [p.committee, p.user.name]}
    if current_user
      @current_player = players.find_by(user_id: current_user.id)
    end
  end

  def leaderboard
    @assassins_all_ranked = Player.where(game_id: @game.id, role: Player::ROLE_ASSASSIN).sort_by { |p| [-1 * (p.points || 0), p.alive? ? 0 : 1, p.committee, p.user.name]}
    committee_points_hash = Hash.new
    @assassins_all_ranked.each do |assassin|
      if committee_points_hash.key?(assassin.committee)
        committee_points_hash[assassin.committee] += assassin.points
      else
        committee_points_hash[assassin.committee] = assassin.points
      end
    end
    @committees_ranked =  committee_points_hash.sort_by{|committee, points| [-1 * (points || 0), committee]}
    if current_user
      @current_player = Player.find_by(user_id: current_user.id, game_id: @game.id)
    end
  end

  def manage
    @players = @game.players.sort_by { |p| [p.role.eql?(Player::ROLE_GAMEMAKER) ? 0 : p.role.eql?(Player::ROLE_ASSASSIN) ? 1 : 2, p.committee, p.user.name]}
    if current_user
      @current_player = Player.find_by(user_id: current_user.id, game_id: @game.id)
    end
  end

  def reassign_roles
    if current_user
      @current_player = Player.find_by(user_id: current_user.id, game_id: @game.id)
    end
    redirect_to game_manage_path(name: @game.name)
  end

  def history
    assassination_history_assignments_all = Assignment.where(game_id: @game.id,status: [Assignment::STATUS_COMPLETED, Assignment::STATUS_BACKFIRED]).order(time_deactivated: :desc)
    @assassination_history_info_all = Array.new
    @assassination_history_info_public = Array.new
    assassination_history_assignments_all.each do |assassination|
      if assassination.is_completed
        @assassination_history_info_all.append([assassination.time_deactivated.to_s, Player.find(assassination.assassin_id).user.name, Player.find(assassination.target_id).user.name, 'forward kill'])
        @assassination_history_info_public.append([assassination.time_deactivated.to_s, Player.find(assassination.target_id).user.name])
      else
        @assassination_history_info_all.append([assassination.time_deactivated.to_s, Player.find(assassination.target_id).user.name, Player.find(assassination.assassin_id).user.name, 'reverse kill'])
        @assassination_history_info_public.append([assassination.time_deactivated.to_s, Player.find(assassination.assassin_id).user.name])
      end
    end
    if current_user
      @current_player = Player.find_by(user_id: current_user.id, game_id: @game.id)
      if @current_player and @current_player.is_assassin
        assassination_history_assignments_self = assassination_history_assignments_all
          .where('(assassin_id = ? AND status = ?) OR (target_id = ? AND status = ?)', @current_player.id, Assignment::STATUS_COMPLETED, @current_player.id, Assignment::STATUS_BACKFIRED)
          .order(time_deactivated: :desc)
        @assassination_history_info_self = Array.new
        assassination_history_assignments_self.each do |assassination|
          if assassination.is_completed
            @assassination_history_info_self.append([assassination.time_deactivated.to_s, Player.find(assassination.target_id).user.name, 'forward kill'])
          else
            @assassination_history_info_self.append([assassination.time_deactivated.to_s, Player.find(assassination.assassin_id).user.name, 'reverse kill'])
          end
        end
      end
      if @current_player and not @current_player.alive
        # Needs to find multiple death assignments if an assassin is allowed to be revived in the future
        # Find death by forward kill
        death_assignment = assassination_history_assignments_all.find_by(target_id: @current_player.id, status: Assignment::STATUS_COMPLETED)
        if death_assignment.nil?
          # Find death by reverse kill
          death_assignment = assassination_history_assignments_all.find_by(assassin_id: @current_player.id, status: Assignment::STATUS_BACKFIRED)
          killer_name = Player.find(death_assignment.target_id).user.name
          @death_info = [death_assignment.time_deactivated.to_s, killer_name, 'reverse kill']
        else
          killer_name = Player.find(death_assignment.assassin_id).user.name
          @death_info = [death_assignment.time_deactivated.to_s, killer_name, 'forward kill']
        end
      end
    end
  end


  def sponsors
    @sponsors = @game.players.where('role = ? OR alive = ?', Player::ROLE_GAMEMAKER, false).sort_by { |p| [-1 * p.sponsor_points, p.user.name]}
    @notes = @game.notes.order(created_at: :desc)
    if current_user
      @current_player = Player.find_by(user_id: current_user.id, game_id: @game.id)
    end
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
      flash[:warning] = 'Error: You do not have the gamemaker clearance to perform the action.'
      redirect_to root_path
    end
  end
end