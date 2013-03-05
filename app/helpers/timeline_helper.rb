# coding: utf-8
module ROGv
  ROGv::Server.helpers do

    def timeline_span_size
      case
      when gvtype_fe?
        12
      when gvtype_te?
        6
      end
    end

    def create_name_table(names)
      ns = [names].flatten.uniq.compact
      return {} if ns.empty?

      h = {}
      if ns.size == 1
        h[ns.first] = '★'
      else
        ch = 'A'
        ns.each do |n|
          h[n] = ch
          ch = ch.succ
        end
      end

      h
    end

    def exist_timeline_gvdates_pair?(from, to)
      return false unless (from && to)
      return false unless (valid_gvdate?(from) && valid_gvdate?(to))
      return false unless (timeline_dates.include?(from) && timeline_dates.include?(to))
      true
    end

    def valid_span_timeline_size?(n)
      return false unless n
      return false if n < 2
      return false if n > ServerSettings.timeline_max_size
      true
    end

  end
end
