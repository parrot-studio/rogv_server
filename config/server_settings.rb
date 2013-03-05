# coding: utf-8
module ROGv
  class ServerSettings < Settingslogic
    source File.expand_path(File.join(PADRINO_ROOT, 'config', 'settings.yml'))
    namespace PADRINO_ENV
    load!

    class << self

      def sample_mode?
        self.env.sample_mode ? true : false
      end

      def view_mode?
        self.env.view_mode ? true : false
      end

      def gvtype
        t = self.env.gvtype.to_s
        case t.upcase
        when 'FE', 'SE', 'FESE'
          'FE'
        when 'TE'
          'TE'
        else
          'FE'
        end
      end

      def gvtype_fe?
        gvtype == 'FE' ? true : false
      end

      def gvtype_te?
        gvtype == 'TE' ? true : false
      end

      def memcache_url
        "#{self.memcache.server}:#{self.memcache.port}"
      end

      def use_memcache?
        self.cache.memcache ? true : false
      end

      def use_db_cache?
        self.cache.db ? true : false
      end

      def result_recently_size_default
        6
      end

      def result_min_size
        val = self.env.result.min_size.to_i
        return 4 if val < 1
        val
      end

      def result_max_size
        val = self.env.result.max_size.to_i
        return 12 if val < 1
        val
      end

      def result_recently_size
        val = self.env.result.recently_size.to_i
        return result_recently_size_defalut if val < result_min_size || val > result_max_size
        val
      end

      def timeline_max_size
        val = self.env.timeline.max_size.to_i
        val > 1 ? val : 1
      end

      def viewer_target
        t = "#{self.viewer.host}"
        t << ":#{self.viewer.port}" unless self.viewer.port.blank?
        t << "#{self.viewer.path}" unless self.viewer.path.blank?
        t
      end

    end

  end
end
