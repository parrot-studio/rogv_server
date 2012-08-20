# coding: utf-8
require 'yaml'

module ROGv
  class ServerConfig

    CONFIGS = lambda do
      data = YAML.load(File.read(File.join(PADRINO_ROOT, 'config', 'config.yml')))
      data[PADRINO_ENV].freeze
    end.call

    class << self

      def auth_key
        return unless CONFIGS[:auth]
        CONFIGS[:auth][:key]
      end

      def auth_username
        return unless CONFIGS[:auth]
        CONFIGS[:auth][:username]
      end

      def auth_password
        return unless CONFIGS[:auth]
        CONFIGS[:auth][:password]
      end

      def auth_delete_key
        return unless CONFIGS[:auth]
        CONFIGS[:auth][:delete_key]
      end

      def auth_sample_mode
        return unless CONFIGS[:auth]
        CONFIGS[:auth][:sample_mode]
      end

      def auth_view_mode
        return unless CONFIGS[:auth]
        CONFIGS[:auth][:view_mode]
      end

      def app_path
        CONFIGS[:app_path] || ''
      end

      def memcache_server
        return unless CONFIGS[:memcache]
        CONFIGS[:memcache][:server]
      end

      def memcache_port
        return unless CONFIGS[:memcache]
        CONFIGS[:memcache][:port]
      end

      def memcache_url
        "#{memcache_server}:#{memcache_port}"
      end

      def memcache_header
        return unless CONFIGS[:memcache]
        CONFIGS[:memcache][:header]
      end

      def use_cache?
        CONFIGS[:use_cache] ? true : false
      end

      def server_name
        CONFIGS[:server_name]
      end

      def attention_minitues
        CONFIGS[:attention_minitues].to_i
      end

      def db_name
        return unless CONFIGS[:db]
        CONFIGS[:db][:name]
      end

      def db_user
        return unless CONFIGS[:db]
        CONFIGS[:db][:user]
      end

      def db_pass
        return unless CONFIGS[:db]
        CONFIGS[:db][:pass]
      end

      def admin_user
        return unless CONFIGS[:admin]
        CONFIGS[:admin][:user]
      end

      def admin_pass
        return unless CONFIGS[:admin]
        CONFIGS[:admin][:pass]
      end

      def admin_expire_sec
        return unless CONFIGS[:admin]
        CONFIGS[:admin][:expire_sec].to_i
      end

      def result_recently_size_default
        6
      end

      def result_min_size
        return 4 unless CONFIGS[:result]
        val = CONFIGS[:result][:min_size].to_i
        return 4 if val < 1
        val
      end

      def result_max_size
        return 12 unless CONFIGS[:result]
        val = CONFIGS[:result][:max_size].to_i
        return 12 if val < 1
        val
      end

      def result_recently_size
        return result_recently_size_default unless CONFIGS[:result]
        val = CONFIGS[:result][:recently_size].to_i
        return result_recently_size_defalut if val < result_min_size || val > result_max_size
        val
      end

      def result_store?
        return false unless CONFIGS[:result]
        CONFIGS[:result][:store] ? true : false
      end
    end

  end
end