# coding: utf-8
require 'yaml'

module ROGv
  class ServerConfig

    CONFIGS = lambda do
      data = YAML.load(File.read(File.join(APP_ROOT, 'config', 'config.yml')))
      data[APP_ENV]
    end.call

    class << self

      def auth_key
        CONFIGS[:auth][:key]
      end

      def auth_username
        CONFIGS[:auth][:username]
      end

      def auth_password
        CONFIGS[:auth][:password]
      end

      def app_path
        CONFIGS[:app_path] || ''
      end

      def memcache_server
        CONFIGS[:memcache][:server]
      end

      def memcache_port
        CONFIGS[:memcache][:port]
      end

      def server_name
        CONFIGS[:server_name]
      end
    end

  end
end
