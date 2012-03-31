# coding: utf-8
module ROGv
  Fort = Struct.new :id, :name, :formal_name, :guild_name, :update_time

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
      @cache ||= {:update_time => nil, :forts => {}}
      @cache
    end

    def forts
      cache[:forts] ||= {}
      cache[:forts]
    end

    def update_time
      cache[:update_time]
    end

    def update_forts(h)
      return unless h
      return if h.empty?

      utime = h.delete('update_time')
      return unless utime
      time = Time.parse(utime)
      return if (cache[:update_time] && cache[:update_time] > time)

      update = false
      h.each do |k, d|
        data = Fort.new
        data.id = k
        data.formal_name = d['formal_name']
        data.guild_name = d['guild_name']
        data.update_time = Time.parse(d['update_time'])

        f = forts[k]
        forts[k] = if f
          changed?(f, data) ? data : f
        else
          data
        end
        update = true if forts[k] == data
      end
      cache[:update_time] = time if update

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
      delete_temp_file
      self
    end

    private

    def changed?(fort, data)
      return false unless (fort && data)
      return false if fort.update_time > data.update_time
      return false if fort.guild_name == data.guild_name
      true
    end
  end
end
