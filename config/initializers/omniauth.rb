Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV['PBLASSASSINS_GOOGLE_CLIENT_ID'], ENV['PBLASSASSINS_GOOGLE_CLIENT_SECRET'], scope: ['profile', 'email']
end