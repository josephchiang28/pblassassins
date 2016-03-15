class PagesController < ApplicationController
  def index
    @games = Game.all.sort_by { |g| g.created_at}.reverse
  end
end