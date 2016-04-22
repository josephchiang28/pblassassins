class AssignmentsController < ApplicationController
  before_action :find_game_by_name, only: [:show, :manual_reassign]
  before_action :find_game_by_id, only: [:generate_assignments, :activate_assignments, :kill]
  before_action :verify_gamemaker_clearance, only: [:generate_assignments, :activate_assignments, :manual_reassign]
  before_action :verify_assassin_clearance, only: [:kill]

  def show
    if current_user
      @current_player = Player.find_by(user_id: current_user.id, game_id: @game.id)
      if not @current_player or @current_player.is_spectator
        flash[:warning] = 'Error: You do not have clearance to view the assignments of game "' + params[:name] + '".'
        redirect_to game_index_path(@game.name)
      elsif @current_player.is_gamemaker
        assignments_all = @game.assignments
        assignments_active = assignments_all.where(status: Assignment::STATUS_ACTIVE)
        assignments_inactive = assignments_all.where(status: Assignment::STATUS_INACTIVE)
        assignments_old = assignments_all.where.not(status: [Assignment::STATUS_ACTIVE, Assignment::STATUS_INACTIVE]).order(time_deactivated: :desc)
        @assignments_active_ordered_assassins = Assignment.get_ring_from_assignments(assignments_active)
        @assignments_inactive_ordered_assassins = Array.new
        # if @game.is_pending or Assignment.verify_inactive_assignments(assignments_active, assignments_inactive)
        @assignments_inactive_ordered_assassins = Assignment.get_ring_from_assignments(assignments_inactive)
        # end
        if @game.is_pending
          @assignments_manual_ordered_assassins = Array.new(@assignments_inactive_ordered_assassins)
        elsif @game.is_active
          @assignments_manual_ordered_assassins = Array.new(@assignments_active_ordered_assassins)
        else
          @assignments_manual_ordered_assassins = Array.new
        end
        assassins_live = @game.players.where(role: Player::ROLE_ASSASSIN_LIVE)
        assassins_live.each do |assassin|
          if not @assignments_manual_ordered_assassins.include?(assassin)
            @assignments_manual_ordered_assassins.append(assassin)
          end
        end
        @assignments_old_info = Array.new
        assignments_old.each do |a|
          @assignments_old_info.append([a.time_deactivated, Player.find(a.assassin_id).user.name, Player.find(a.target_id).user.name, a.status])
        end
      elsif @current_player.is_assassin
        @assignment = @game.assignments.find_by(assassin_id: @current_player.id, status: Assignment::STATUS_ACTIVE)
        @assassins_alive = @game.players.where(role: Player::ROLE_ASSASSIN_LIVE)
      end
    else
      flash[:warning] = 'Error: You do not have clearance to view the assignments of game "' + params[:name] + '".'
      redirect_to game_index_path(@game.name)
    end
  end

  def generate_assignments
    # TODO: Need to do error handling if assignments successfully generated
    Assignment.generate_assignments(@game.id, 'all')
    redirect_to show_assignments_path
  end

  def activate_assignments
    # TODO: Need to do error handling if assignments successfully activated
    Assignment.discard_old_and_activate_new_assignments(@game.id)
    redirect_to show_assignments_path
  end

  def manual_reassign
    ring_assassin_ids = params[:ring_assassin_ids]
    ring_assassins = ring_assassin_ids.map { |id| Player.find(id) }
    # TODO: Make sure destroy and create are in one transaction
    Assignment.destroy_inactive_assignments(@game.id)
    Assignment.create_assignments_from_ring(ring_assassins)
    redirect_to show_assignments_path
  end

  def kill
    if params[:commit].eql?(Assignment::PUBLIC_ENEMY_KILL_TEXT) and not @game.public_enemy_mode?
      flash[:warning] = 'ERROR: Public enemy kill not allowed because public enemy mode not activated.'
      return redirect_to show_assignments_path(name: @game.name)
    end
    if params[:commit].eql?(Assignment::FORWARD_KILL_TEXT) or params[:commit].eql?(Assignment::REVERSE_KILL_TEXT) or params[:commit].eql?(Assignment::PUBLIC_ENEMY_KILL_TEXT)
      if Assignment.register_kill(@assassin, params[:victim_name], params[:killcode], params[:commit])
        if @game.is_completed
          flash[:success] = 'Kill code confirmed. Congratulations, you are the last surviving assassin!'
        elsif params[:commit].eql?(Assignment::FORWARD_KILL_TEXT)
          flash[:success] = 'Kill code confirmed. Forward kill registered and a new target is assigned.'
        elsif params[:commit].eql?(Assignment::REVERSE_KILL_TEXT)
          flash[:success] = 'Kill code confirmed. Reverse kill registered and you are a new target of an assassin.'
        elsif params[:commit].eql?(Assignment::PUBLIC_ENEMY_KILL_TEXT)
          flash[:success] = 'Kill code confirmed. Public enemy kill registered.'
        end
      else
        flash[:warning] = 'ERROR: Victim name or kill code incorrect or victim not public enemy. Kill not registered.'
      end
    else
      flash[:warning] = 'ERROR: Invalid commit type.'
    end
    redirect_to show_assignments_path(name: @game.name)
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

  def find_game_by_id
    begin
      @game = Game.find_by!(id: params[:game_id])
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

  def verify_assassin_clearance
    has_assassin_clearance = false
    if current_user
      @assassin = Player.find_by(user_id: current_user.id, game_id: @game.id)
      if @assassin and @assassin.is_assassin
        has_assassin_clearance = true
      end
    end
    if not has_assassin_clearance
      flash[:warning] = 'Error: You do not have the assassin clearance to perform the action.'
      redirect_to root_path
    end
  end

end