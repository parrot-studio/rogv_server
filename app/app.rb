# coding: utf-8
require 'base64'
require 'securerandom'
require 'digest/sha1'

module ROGv
  class Server < Padrino::Application
    register Padrino::Rendering
    register Padrino::Mailer
    register Padrino::Helpers

    enable :sessions

    register Padrino::Cache
    enable :caching
    set :cache, Padrino::Cache::Store::Memcache.new(
      ::Dalli::Client.new(ServerConfig.memcache_url, :exception_retry_limit => 1))

    include DataCache
    include AdminAuth

    ##
    # Application configuration options
    #
    # set :raise_errors, true       # Raise exceptions (will stop application) (default for test)
    # set :dump_errors, true        # Exception backtraces are written to STDERR (default for production/development)
    # set :show_exceptions, true    # Shows a stack trace in browser (default for development)
    # set :logging, true            # Logging in STDOUT for development and file for production (default only for development)
    # set :public_folder, "foo/bar" # Location for static assets (default root/public)
    # set :reload, false            # Reload application files (default in development)
    # set :default_builder, "foo"   # Set a custom form builder (default 'StandardFormBuilder')
    # set :locale_path, "bar"       # Set path for I18n translations (default your_app/locales)
    # disable :sessions             # Disabled sessions by default (enable if needed)
    # disable :flash                # Disables sinatra-flash (enabled by default if Sinatra::Flash is defined)
    # layout  :my_layout            # Layout can be in views/layouts/foo.ext or views/foo.ext (default :application)
    #

    unless ServerConfig.auth_sample_mode
      use Rack::Auth::Basic do |user, pass|
        user == ServerConfig.auth_username && pass == ServerConfig.auth_password
      end
    end

    not_found do
      render :not_found, :layout => :application
    end

    error do
      render :error, :layout => :application
    end

    private

    def date_action
      @date = params[:date]
      redirect url_for(:date_list) unless @date
      redirect url_for(:date_list) unless Situation.date_list.include?(@date)
      yield(@date)
    end

    def protect_action
      (halt 403) unless updatable_mode?
      (halt 403) unless params['k'] == ServerConfig.auth_key
      yield if block_given?
    end

    def valid_delete_key?(dkey)
      return false unless dkey
      return false if dkey.empty?
      dkey == ServerConfig.auth_delete_key ? true : false
    end

    def encode_base64_for_url(s)
      Base64.urlsafe_encode64(s)
    end

    def decode_base64_for_url(s)
      Base64.urlsafe_decode64(s).force_encoding('UTF-8')
    end

    def parse_guild_params(gname, names)
      return [] if gname.nil? || gname.empty? || names.empty?
      [gname].flatten.uniq.compact.reject(&:empty?).select{|n| names.include?(n)}
    end

    def parse_union_code(code, names)
      return [] if code.nil? || code.empty? || names.empty?
      code.split(/,/).uniq.compact.reject(&:empty?).map{|s| decode_base64_for_url(s)}.select{|g| names.include?(g)}
    end

    def create_union_code(gs)
      [gs].flatten.uniq.compact.reject(&:empty?).map{|n| encode_base64_for_url(n)}.flatten.join(',')
    end
  end
end