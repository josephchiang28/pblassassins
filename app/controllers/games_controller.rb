class GamesController < ApplicationController
  def index
    @game = Game.where(name: params[:name]).first
    if @game.nil?
      flash[:warning] = 'Error: The game ' + params[:name] + ' does not exist.'
      return redirect_to root_path
    end
    players = @game.players
    @gamemakers = players.where(role: Player::ROLE_GAMEMAKER).sort_by { |p| p.committee}
    @assassins = players.where(role: Player::ROLE_ASSASSIN).sort_by { |p| p.committee}
    @spectators = players.where(role: Player::ROLE_SPECTATOR).sort_by { |p| p.committee}
    if current_user
      @current_player = players.where(user_id: current_user.id).first
    end
  end

  def profile
    @game = Game.where(name: params[:name]).first
    if @game.nil?
      flash[:warning] = 'Error: The game ' + params[:name] + ' does not exist.'
      return redirect_to root_path
    end
    if current_user
      @current_player = Player.where(user_id: current_user.id, game_id: @game.id).first
      if @current_player.nil?
        flash[:warning] = 'Error: Your profile for the game ' + params[:name] + ' does not exist.'
        redirect_to root_path
      end
    else
      flash[:warning] = 'Error: Please sign in to view your profile.'
      redirect_to root_path
    end
  end

  def leaderboard
    @game = Game.where(name: params[:name]).first
    if @game.nil?
      flash[:warning] = 'Error: The game ' + params[:name] + ' does not exist.'
      return redirect_to root_path
    end
    @assassins_all_ranked = Player.where(game_id: @game.id, role: Player::ROLE_ASSASSIN).sort_by { |p| [-1 * (p.points || 0), p.committee, p.user.email]}
    @assassins_live_ranked = Array.new
    @assassins_dead_ranked = Array.new
    committee_points_hash = Hash.new
    @assassins_all_ranked.each do |assassin|
      if assassin.alive?
        @assassins_live_ranked.append(assassin)
      else
        @assassins_dead_ranked.append(assassin)
      end
      if committee_points_hash.key?(assassin.committee)
        committee_points_hash[assassin.committee] += assassin.points
      else
        committee_points_hash[assassin.committee] = assassin.points
      end
    end
    @committees_ranked =  committee_points_hash.sort_by{|committee, points| [points, committee]}
    if current_user
      @current_player = Player.where(user_id: current_user.id, game_id: @game.id).first
    end
  end

  def history
    @game = Game.where(name: params[:name]).first
    if @game.nil?
      flash[:warning] = 'Error: The game ' + params[:name] + ' does not exist.'
      return redirect_to root_path
    end
    assassination_history_assignments_all = Assignment.where(game_id: @game.id,status: [Assignment::STATUS_COMPLETED, Assignment::STATUS_BACKFIRED])
    @assassination_history_info_all = Array.new
    @assassination_history_info_public = Array.new
    assassination_history_assignments_all.sort_by { |a| a.time_deactivated }.each do |assassination|
      if assassination.is_completed
        @assassination_history_info_all.append([assassination.time_deactivated.to_s, Player.find(assassination.assassin_id).user.email, Player.find(assassination.target_id).user.email, 'forward kill'])
        @assassination_history_info_public.append([assassination.time_deactivated.to_s, Player.find(assassination.target_id).user.email])
      else
        @assassination_history_info_all.append([assassination.time_deactivated.to_s, Player.find(assassination.target_id).user.email, Player.find(assassination.assassin_id).user.email, 'reverse kill'])
        @assassination_history_info_public.append([assassination.time_deactivated.to_s, Player.find(assassination.assassin_id).user.email])
      end
    end
    if current_user
      @current_player = Player.where(user_id: current_user.id, game_id: @game.id).first
      if @current_player and @current_player.is_assassin
        assassination_history_assignments_self = assassination_history_assignments_all.where(assassin_id: @current_player.id, status: Assignment::STATUS_COMPLETED)
        assassination_history_assignments_self += assassination_history_assignments_all.where(target_id: @current_player.id, status: Assignment::STATUS_BACKFIRED)
        assassination_history_assignments_self = assassination_history_assignments_self.sort_by { |a| a.time_deactivated }
        @assassination_history_info_self = Array.new
        assassination_history_assignments_self.each do |assassination|
          if assassination.is_completed
            @assassination_history_info_self.append([assassination.time_deactivated.to_s, Player.find(assassination.target_id).user.email, 'forward kill'])
          else
            @assassination_history_info_self.append([assassination.time_deactivated.to_s, Player.find(assassination.assassin_id).user.email, 'reverse kill'])
          end
        end
      end
      if @current_player and not @current_player.alive
        # Find death by forward kill
        death_assignment = assassination_history_assignments_all.where(target_id: @current_player.id, status: Assignment::STATUS_COMPLETED).first
        if death_assignment.nil?
          # Find death by reverse kill
          death_assignment = assassination_history_assignments_all.where(assassin_id: @current_player.id, status: Assignment::STATUS_BACKFIRED).first
          killer_email = Player.find(death_assignment.target_id).user.email
          @death_info = [death_assignment.time_deactivated.to_s, killer_email, 'reverse kill']
        else
          killer_email = Player.find(death_assignment.assassin_id).user.email
          @death_info = [death_assignment.time_deactivated.to_s, killer_email, 'forward kill']
        end
      end
    end
  end


  def sponsors
    @game = Game.where(name: params[:name]).first
    if @game.nil?
      flash[:warning] = 'Error: The game ' + params[:name] + ' does not exist.'
      return redirect_to root_path
    end
    if current_user
      @current_player = Player.where(user_id: current_user.id, game_id: @game.id).first
      @sponsors = @game.players.where(alive: false)
    end
  end
  
  def update_sponsor_points
    @game = Game.where(name: params[:name]).first
    if current_user
      player = @game.players.where(id: params[:player_id]).first
      player.update_points(params[:new_points])
    end
    redirect_to game_sponsors_path(@game.name)
  end

  def rules
    @game = Game.where(name: params[:name]).first
    if @game.nil?
      flash[:warning] = 'Error: The game ' + params[:name] + ' does not exist.'
      return redirect_to root_path
    end
    if current_user
      @current_player = Player.where(user_id: current_user.id, game_id: @game.id).first
    end
  end
end