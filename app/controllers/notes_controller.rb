class NotesController < ApplicationController
  def create
    @game = Game.where(name: params[:name]).first
    if @game.nil?
      flash[:warning] = 'Error: The game ' + params[:name] + ' does not exist.'
      return redirect_to root_path
    end
    Note.create!(game_id: @game.id, content: params[:content])
    redirect_to game_sponsors_path(@game.name)
  end

  def delete
    @game = Game.where(name: params[:name]).first
    if @game.nil?
      flash[:warning] = 'Error: The game ' + params[:name] + ' does not exist.'
      return redirect_to root_path
    end
    if current_user
      @current_player = Player.where(user_id: current_user.id, game_id: @game.id).first
    end
    if @current_player and @current_player.is_gamemaker
      Note.destroy(params[:note_id])
    else
      flash[:warning] = 'Ooops, you do not have permission to delete the note.'
      return redirect_to root_path
    end
    redirect_to game_sponsors_path(@game.name)
  end
end