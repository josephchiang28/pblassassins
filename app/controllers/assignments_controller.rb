class AssignmentsController < ApplicationController
  def show
    @game = Game.where(name: params[:name]).first
    if current_user
      @current_player = Player.where(user_id: current_user.id, game_id: @game.id).first
      if @current_player.is_gamemaker
        @all_assignments = @game.assignments
        @assignments_active = @assignments.to_a.keep_if {|a| a.is_active}
        @assassins_ring = []
        @all_assignments.each do |assignment|
          @assassins_ring.append(Player.find(assignment.assassin_id))
        end
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
end