# coding: utf-8
module ROGv
  class TotalRebuilder

    attr_accessor :from, :silent

    def execute
      mes "date from  : #{@from}" if @from
      mes "repair_duplication"
      repair_duplication
      mes "drop_weekly_result"
      drop_weekly_result
      mes "totalize_weekly_result"
      totalize_weekly_result
      mes "drop_total_result"
      drop_total_result
      mes "totalize_total_result"
      totalize_total_result
      mes "fort_result"
      add_fort_result
      mes "clear_cache"
      clear_cache
      mes "complete!"
      true
    end

    private

    def mes(m)
      return if @silent
      puts m
    end

    def repair_duplication
      dlist = Situation.date_list
      dlist = dlist.select{|d| d >= @from} if @from
      dlist.each{|d| Situation.repair_duplication!(d)}
    end

    def drop_weekly_result
      WeeklyResult.all.select{|r| r.source.blank?}.each(&:destroy)
    end

    def totalize_weekly_result
      WeeklyResult.analyze_all!(:from => @from, :force => true)
    end

    def drop_total_result
      TotalResult.all.each(&:destroy)
    end

    def totalize_total_result
      WeeklyResult.date_list.each{|d| TotalResult.add_result_to_all_total!(d)}
    end

    def add_fort_result
      FortResult.all.each(&:destroy)
      WeeklyResult.sort(:gv_date.asc).each do |wr|
        case
        when wr.analyzed?
          FortResult.add_result(wr.gv_date)
        when wr.manual?
          FortResult.add_manual_result(wr)
        end
      end
    end

    def clear_cache
      TotalResult.cache_clear!
      FortTimeline.cache_clear!
      GuildTimeline.cache_clear!
    end

  end
end
