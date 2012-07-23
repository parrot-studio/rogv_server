# coding: utf-8
module ROGv
  ROGv::Server.helpers do

    def logined?
      hash = session[:hash]
      return false unless hash
      hash == create_hash(session[:user], session[:seed]) ? true : false
    end

  end
end
