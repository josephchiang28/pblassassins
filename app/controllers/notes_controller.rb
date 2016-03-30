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
end