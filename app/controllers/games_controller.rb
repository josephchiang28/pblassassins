class GamesController < ApplicationController
  def index
    @game = Game.where(name: params[:name]).first
    @gamemakers = Player.where(game_id: @game.id, role: Player::ROLE_GAMEMAKER).sort_by { |p| p.committee}
    @assassins = Player.where(game_id: @game.id, role: Player::ROLE_ASSASSIN).sort_by { |p| p.committee}
    @current_player = Player.where(user_id: current_user.id, game_id: @game.id).first
  end

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