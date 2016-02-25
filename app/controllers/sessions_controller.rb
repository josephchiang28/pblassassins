class SessionsController < ApplicationController
  def create
    begin
      @user = User.from_omniauth(request.env['omniauth.auth'])
      session[:user_id] = @user.id
      flash[:success] = 'Welcome, ' + @user.name
    rescue Exception => e
      puts 'SIGN IN ERROR: ' + e.message
      flash[:warning] = 'Ooops. There was an error while trying to authenticate you...'
    end
    redirect_to root_path
  end

  def destroy
    if current_user
      session.delete(:user_id)
      flash[:success] = 'You have successfully signed out'
    end
    redirect_to root_path
  end
end