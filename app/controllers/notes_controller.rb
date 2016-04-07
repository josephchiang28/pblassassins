class NotesController < ApplicationController
  before_action :find_game_by_name
  before_action :verify_gamemaker_clearance

  def create
    Note.create!(game_id: @game.id, content: params[:content])
    redirect_to game_index_path(@game.name)
  end

  def delete
    Note.destroy(params[:note_id])
    redirect_to game_index_path(@game.name)
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