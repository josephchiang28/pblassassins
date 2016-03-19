class SessionsController < ApplicationController
  def create
    begin
      auth_hash = request.env['omniauth.auth']
      @user = User.from_omniauth(auth_hash)
      if @user.nil?
        flash[:warning] = 'Error: Your email ' + auth_hash.info.email + ' is not in the white list.'
      else
        session[:user_id] = @user.id
        flash[:success] = 'Welcome, ' + @user.name
      end
    rescue Exception => e
      puts 'LOGIN ERROR: ' + e.message
      flash[:warning] = 'Ooops. There was an error while trying to authenticate you...'
    end
    redirect_to root_path
  end

  def destroy
    if current_user
      session.delete(:user_id)
      flash[:success] = 'You have successfully logged out'
    end
    redirect_to root_path
  end

  # For testing purposes only, remove or comment out later
  def mock_user_login
    @user = User.where(email: params[:email]).first
    if @user.nil?
      flash[:warning] = 'Error: Your email ' + params[:email] + ' is not in the white list.'
    else
      session[:user_id] = @user.id
      flash[:success] = 'Mocked user login of ' + @user.email
    end
    redirect_to root_path
  end

end