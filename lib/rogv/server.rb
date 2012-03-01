# coding: utf-8
require 'date'
require 'json'
require 'sinatra/base'

module ROGv
  class Server < Sinatra::Base
    set :root, File.expand_path(File.join(APP_ROOT, 'web'))

    use Rack::Auth::Basic do |user, pass|
      user == ServerConfig.auth_username && pass == ServerConfig.auth_password
    end

    helpers do
      include Rack::Utils
      alias_method :h, :escape_html
      alias_method :u, :escape

      def app_path
        ServerConfig.app_path
      end

      def format_date(d)
        return unless d
        format("%04d/%02d/%02d %02d:%02d:%02d",
          d.year, d.month, d.day, d.hour, d.minute, d.second)
      end
    end

    get '/' do
      mapper = ROGv::FortMapper.instance
      @forts = mapper.forts
      @update_time = mapper.update_time
      erb :index
    end

    post '/' do
      protect_action do
        data = JSON.parse(params['d'])
        ROGv::FortMapper.instance.update(data)
      end
    end

    post '/status' do
      protect_action
    end

    delete '/reset' do
      protect_action do
        ROGv::FortMapper.instance.reset
      end
    end

    private

    def protect_action
      (halt 403) unless params['k'] == ServerConfig.auth_key
      yield if block_given?
      'OK'
    end

  end
end
