class User < ActiveRecord::Base
  has_many :players
  validates :email, presence: true, uniqueness: true

  # Only allow and update users that are manually entered by admin
  def self.from_omniauth(auth_hash)
    user = User.find_by(email: auth_hash.info.email)
    if not user.nil?
      # user.name = auth_hash.info.name
      user.provider = auth_hash.provider
      user.uid = auth_hash.uid
      user.save!
    end
    user
  end
end
