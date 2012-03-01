# coding: utf-8
require 'date'
require 'yaml'
require 'singleton'

module ROGv
  Fort = Struct.new :id, :name, :formal_name, :guild_name

  class FortMapper
    include Singleton

    CACHE_KEY = '_rogv_forts_data'
    
    def update(h)
      update_forts(h)
      update_cache
      replace_temp_file
    end

    def cache
      @cache ||= (read_cache || read_temp_file)
      @cache ||= {:update_date => nil, :forts => {}}
      @cache
    end

    def forts
      cache[:forts] ||= {}
      cache[:forts]
    end

    def update_time
      cache[:update_date]
    end

    def update_forts(h)
      return unless h
      return if h.empty?

      h.each do |k, d|
        case k
        when 'update_time'
          cache[:update_date] = DateTime.parse(d)
        else
          f = forts[k]
          unless f
            f = Fort.new
            f.id = k
            forts[k] = f
          end
          f.name = d['name']
          f.formal_name = d['formal_name']
          f.guild_name = d['guild_name']
        end
      end

      self
    end
    
    def update_cache
      manager.cache_open do |mem|
        mem.set(CACHE_KEY, cache.to_yaml)
      end
      self
    end

    def reset
      @cache = nil
      manager.cache_open do |mem|
        mem.delete(CACHE_KEY)
      end
      self
    end

    private

    def replace_temp_file
      # TODO
    end

    def read_cache
      manager.cache_open do |mem|
        data = mem.get(CACHE_KEY)
        data ? YAML.load(data) : nil
      end
    end

    def read_temp_file
      # TODO
    end

    def manager
      @manager ||= lambda do
        mem = MemcacheManager.new
        mem.add_server(ServerConfig.memcache_server, ServerConfig.memcache_port)
        mem.expire_time = 4 * 60 * 60
        mem
      end.call
      @manager
    end
  end
end
