class GamesController < ApplicationController
  def leaderboard
    @game = Game.where(name: params[:name]).first
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