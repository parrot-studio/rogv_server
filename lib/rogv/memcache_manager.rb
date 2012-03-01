# coding: UTF-8
require 'dalli'

module ROGv
  class MemcacheManager

    attr_writer :expire_time

    def servers
      @servers ||= []
      @servers
    end

    def add_server(serv, port)
      servers << [serv, port]
    end

    def expire_time
      @expire_time ||= 0
      @expire_time
    end

    def connect
      servs = []
      servers.each do |se, po|
        servs << "#{se}:#{po}"
      end

      @mem = Dalli::Client.new(servs, {:expires_in => expire_time})
      self
    end

    def close
      @mem.close if @mem
      @mem = nil
      self
    end

    def cache_open
      connect
      return self unless block_given?
      ret = yield(self)
      close
      ret
    end

    def get(key)
      return unless @mem
      @mem.get(key.to_s)
    end
    alias :[] :get

    def set(key, val)
      return unless @mem
      @mem.set(key.to_s, val)
    end
    alias :[]= :set

    def delete(key)
      return unless @mem
      @mem.delete(key.to_s)
    end
    alias :del :delete

  end
end
