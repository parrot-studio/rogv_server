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
      WeeklyResult.all.select{|r| r.source.nil? || !r.source.empty}.each(&:destroy)
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

  end
end