class User < ActiveRecord::Base
  has_many :players

  def self.from_omniauth(auth_hash)
    where(provider: auth_hash.provider, uid: auth_hash.uid).first_or_create do |user|
      user.email = auth_hash.info.email
      user.name = auth_hash.info.name
      user.save!
    end
  end
end
