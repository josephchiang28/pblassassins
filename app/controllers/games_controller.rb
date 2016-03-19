class GamesController < ApplicationController
  def index
    @game = Game.where(name: params[:name]).first
    @gamemakers = Player.where(game_id: @game.id, role: Player::ROLE_GAMEMAKER).sort_by { |p| p.committee}
    @assassins = Player.where(game_id: @game.id, role: Player::ROLE_ASSASSIN).sort_by { |p| p.committee}
    if current_user
      @current_player = Player.where(user_id: current_user.id, game_id: @game.id).first
    end
  end

  def profile
    @game = Game.where(name: params[:name]).first
    if current_user
      @current_player = Player.where(user_id: current_user.id, game_id: @game.id).first
    end
  end

  def leaderboard
    @game = Game.where(name: params[:name]).first
    @assassins_ranked = Player.where(game_id: @game.id, role: Player::ROLE_ASSASSIN).sort_by { |p| [-1 * (p.points || 0), p.committee, p.user.email]}
    committee_points_hash = Hash.new
    @assassins_ranked.each do |assassin|
      if committee_points_hash.key?(assassin.committee)
        committee_points_hash[assassin.committee] += assassin.points
      else
        committee_points_hash[assassin.committee] = assassin.points
      end
    end
    @committees_ranked =  committee_points_hash.sort_by{|committee, points| [points, committee]}
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