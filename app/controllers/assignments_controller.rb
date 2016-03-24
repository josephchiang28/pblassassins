class AssignmentsController < ApplicationController
  def show
    @game = Game.where(name: params[:name]).first
    if current_user
      @current_player = Player.where(user_id: current_user.id, game_id: @game.id).first
      if @current_player.is_gamemaker
        assignments_all = @game.assignments
        assignments_active = assignments_all.where(status: Assignment::STATUS_ACTIVE)
        assignments_inactive = assignments_all.where(status: Assignment::STATUS_INACTIVE)
        assignments_old = assignments_all.where.not(status: [Assignment::STATUS_ACTIVE, Assignment::STATUS_INACTIVE]).sort_by { |a| a.time_activated}
        @assignments_active_ordered_assassins = Assignment.get_ring_from_assignments(assignments_active)
        @assignments_inactive_ordered_assassins = Assignment.get_ring_from_assignments(assignments_inactive)
        if @game.is_pending
          @assignments_manual_ordered_assassins = Array.new(@assignments_inactive_ordered_assassins)
        elsif @game.is_active
          @assignments_manual_ordered_assassins = Array.new(@assignments_active_ordered_assassins)
        else
          @assignments_manual_ordered_assassins = Array.new
        end
        @assignments_old_info = Array.new
        assignments_old.each do |a|
          @assignments_old_info.append([Player.find(a.assassin_id).user.email, Player.find(a.target_id).user.email, a.status])
        end
      elsif @current_player.is_assassin
        @assignment = @game.assignments.where(assassin_id: @current_player.id, status: Assignment::STATUS_ACTIVE).first
        @assassins_alive = @game.players.where(role: Player::ROLE_ASSASSIN, alive: true)
      else
        # User is spectator, to be implemented
      end
    else
      # Not signed in
    end
  end

  def generate_assignments
    # TODO: Need to do error handling if assignments successfully generated
    Assignment.generate_assignments(params[:game_id], 'all')
    redirect_to show_assignments_path
  end

  def activate_assignments
    # TODO: Need to do error handling if assignments successfully activated
    Assignment.discard_old_and_activate_new_assignments(params[:game_id])
    redirect_to show_assignments_path
  end

  def manual_reassign
    @game = Game.where(name: params[:name]).first
    ring_assassin_ids = params[:ring_assassin_ids]
    ring_assassins = ring_assassin_ids.map { |id| Player.find(id) }
    Assignment.destroy_inactive_assignments(@game.id)
    Assignment.create_assignments_from_ring(ring_assassins)
    redirect_to show_assignments_path
  end

  def kill
    # TODO: Check permissions and if game and assassins found
    game = Game.find(params[:game_id])
    assassin = Player.find(params[:player_id])
    is_reverse_kill = false
    if params[:commit] == 'Reverse Kill'
      is_reverse_kill = true
    end
    if Assignment.register_kill(game, assassin, params[:victim_email], params[:killcode], is_reverse_kill)
      if game.is_completed
        flash[:success] = 'Kill code confirmed. Congratulations, you are the last surviving assassin!'
      elsif is_reverse_kill
        flash[:success] = 'Kill code confirmed. Reverse kill confirmed and you are a new target of an assassin.'
      else
        flash[:success] = 'Kill code confirmed. Forward kill confirmed and a new target is assigned.'
      end
    else
      flash[:warning] = 'Kill code incorrect. Forward or reverse kill not confirmed.'
    end
    redirect_to show_assignments_path(name: game.name)
  end
end