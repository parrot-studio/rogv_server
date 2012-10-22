# coding: utf-8
module ROGv
  class GuildTimelineBuilder

    attr_reader :date

    def self.build_for(date, *names)
      ft = self.new
      return unless ft.build_for(date, names)
      ft
    end

    def build_for(d, ns)
      return unless d
      @date = d
      @names = [ns].flatten.uniq.compact
      return if names.empty?

      ss = Situation.for_date(date).sort_by(&:update_time)
      return if ss.empty?
      bs = Situation.revision_before(ss.first.revision)
      bs = ss.first if (bs.nil? || bs.gv_date != TimeUtil.before_gvdate(date))

      @before_date_fort = create_owner_hash(bs)
      @forts = ss.inject({}){|h, s| h[s.update_time] = create_owner_hash(s); h}

      self
    end

    def names
      @names ||= []
      @names
    end

    def union?(n)
      return false unless n
      names.include?(n) ? true : false
    end

    def times
      @times ||= forts.keys.sort
      @times
    end

    def forts
      @forts ||= {}
      @forts
    end

    def initial_owner(fid)
      @before_date_fort ||= {}
      @before_date_fort[fid]
    end

    def initial_owner?(fid)
      union?(initial_owner(fid)) ? true : false
    end

    def owner(time, fid)
      return unless (time && fid)
      (forts[time] || {})[fid]
    end

    def final_owner(fid)
      owner(times.last, fid)
    end

    def final_owner?(fid)
      union?(final_owner(fid)) ? true : false
    end

    def each_changed_time(all = false)
      bt = nil
      times.each do |ti|
        h = {}
        exist = false
        forts[ti].each do |fid, name|
          next unless name
          beo = (bt ? owner(bt, fid) : initial_owner(fid))
          h[fid] = if union?(name)
            case
            when name == beo
              :stay
            else
              exist = true
              name
            end
          else
            if union?(beo)
              exist = true
              :lose
            end
          end
        end
        yield(ti, h) if (all || exist)
        bt = ti
      end
    end

    private

    def create_owner_hash(s)
      return unless s
      s.forts.inject({}){|h, f| h[f.fort_id] = f.guild_name;h}
    end

  end
end
