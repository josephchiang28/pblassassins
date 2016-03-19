class AssignmentsController < ApplicationController
  def show
    @game = Game.where(name: params[:name]).first
    if current_user
      @current_player = Player.where(user_id: current_user.id, game_id: @game.id).first
      if @current_player.is_gamemaker
        assignments_all = @game.assignments
        assignments_active = assignments_all.where(status: Assignment::STATUS_ACTIVE)
        assignments_inactive = assignments_all.where(status: Assignment::STATUS_INACTIVE)
        @assignments_active_ordered_assassins = Assignment.get_ring_from_assignments(assignments_active)
        @assignments_inactive_ordered_assassins = Assignment.get_ring_from_assignments(assignments_inactive)
      else
        # User is assassin
      end
    else
      # Not signed in
    end
  end

  def generate_assignments
    Assignment.generate_assignments(params[:game_id], 'all')
    redirect_to show_assignments_path
  end

  def activate_assignments
    Assignment.discard_old_and_activate_new_assignments(params[:game_id])
    redirect_to show_assignments_path
  end
end