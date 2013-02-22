# coding: utf-8
module ROGv
  class FortTimelineBuilder

    attr_reader :date

    def self.build_for(date)
      return unless date
      ft = self.new
      return unless ft.build_for(date)
      ft
    end

    def build_for(d)
      return unless d
      @date = d

      ss = Situation.for_date(date).sort_by(&:update_time)
      return if ss.empty?

      @before_date_fort = lambda do
        # 先週のデータから取得
        bs = Situation.revision_before(ss.first.revision)
        next bs.forts_map if (bs && bs.gv_date == TimeUtil.before_gvdate(date))

        # 結果データから取得
        rsl = WeeklyResult.where(:gv_date.lt => date).sort(:gv_date.desc).limit(1).first
        next rsl.forts_map if rsl

        {}
      end.call

      @forts = ss.inject({}){|h, s| h[s.update_time] = s.forts_map; h}

      self
    end

    def times
      @times ||= @forts.keys.sort
      @times
    end

    def forts_for_time(time)
      @forts ||={}
      @forts[time] || {}
    end

    def fort(time, fid)
      forts_for_time(time)[fid]
    end

    def before_date_fort(fid)
      @before_date_fort ||= {}
      @before_date_fort[fid]
    end

    def result
      forts_for_time(times.last)
    end

    def result_for(fid)
      result[fid]
    end

    def stay?(time, fid)
      return false unless (time && fid)
      bt = times.select{|t| t < time}.last
      bf = bt ? fort(bt, fid) : before_date_fort(fid)
      tf = fort(time, fid)
      return false unless (tf && bf)

      bf.guild_name == tf.guild_name ? true : false
    end

    def each_changed_time(targets, all = false)
      times.each do |ti|
        li = []
        exist = false
        targets.each do |ta|
          f = fort(ti, ta)
          li << case
          when f.nil?
            :none
          when stay?(ti, ta)
            :stay
          else
            exist = true
            f.guild_name
          end
        end
        yield(ti, li) if (all || exist)
      end
    end

  end
end
