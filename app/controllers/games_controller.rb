class GamesController < ApplicationController
  def leaderboard
    @game = Game.where(name: params[:name]).first
    @players = Player.where(game_id: @game.id)
  end

  def assignments
    @game = Game.where(name: params[:name]).first
  end

  def history
    @game = Game.where(name: params[:name]).first
  end

  def sponsors
    @game = Game.where(name: params[:name]).first
  end

  def rules
    @game = Game.where(name: params[:name]).first
  end
end