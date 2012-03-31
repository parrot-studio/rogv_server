# coding: utf-8
module ROGv
  class FortTimeline

    attr_reader :date

    def self.build_for(date)
      return unless date
      ft = self.new
      ft.build_for(date)
      ft
    end

    def build_for(d)
      return unless d
      @date = d

      ss = Situation.for_date(date).sort_by(&:update_time)
      return if ss.empty?
      bs = Situation.revision_before(ss.first.revision) || ss.first

      @before_date_fort = bs.forts_map
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

    def result_for(fid)
      fort(times.last, fid)
    end

    def stay?(time, fid)
      return false unless (time && fid)
      bt = times.select{|t| t < time}.last
      return false unless bt

      bf = fort(bt, fid)
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
