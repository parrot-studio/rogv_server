# coding: utf-8
module ROGv
  module AdminAuth

    def valid_admin?(user, pass)
      return false unless ServerConfig.admin_user == user
      return false unless ServerConfig.admin_pass == pass
      true
    end

    def login_for(user)
      return unless user
      seed = SecureRandom.hex(12)
      session[:user] = user
      session[:seed] = seed
      session[:hash] = create_hash(user, seed)
      nil
    end

    def clear_session
      session.delete(:user)
      session.delete(:seed)
      session.delete(:hash)
      nil
    end

    def create_hash(user, seed)
      return unless (user && seed)
      s = "#{user}-#{settings.session_secret}-#{seed}"
      Digest::SHA1.hexdigest(s)
    end

  end
end
