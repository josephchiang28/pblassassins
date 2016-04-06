class NotesController < ApplicationController
  before_action :find_game_by_name

  def create
    Note.create!(game_id: @game.id, content: params[:content])
    redirect_to game_index_path(@game.name)
  end

  def delete
    if current_user
      @current_player = Player.where(user_id: current_user.id, game_id: @game.id).first
    end
    if @current_player and @current_player.is_gamemaker
      Note.destroy(params[:note_id])
    else
      flash[:warning] = 'Ooops, you do not have permission to delete the note.'
      return redirect_to root_path
    end
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
end