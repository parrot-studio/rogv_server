# coding: utf-8
module ROGv
  module DataCache

    def cache_enable?
      return false unless ServerSettings.use_memcache?
      return true if sample_mode?
      TimeUtil.in_battle_time? ? false : true
    end

    def get_with_cache(name, expires, &b)
      return b.call unless cache_enable?
      cache("#{ServerSettings.memcache.header}_#{name}", :expires_in => expires, &b)
    end

    def timeline_dates
      get_with_cache("timeline_dates", 300) do
        Situation.date_list
      end
    end

    def revs_for_date(date)
      return [] unless date
      get_with_cache("revs_for_#{date}", 300) do
        Situation.for_date(date).sort(:revision.desc).map(&:revision)
      end
    end

    def guild_names_for_date(date)
      return [] unless date
      get_with_cache("guild_names_for_#{date}", 300) do
        Situation.guild_names_for(date)
      end
    end

    def result_dates
      get_with_cache("result_dates", 300) do
        WeeklyResult.date_list
      end
    end

    def guild_names_for_all_total
      get_with_cache("guild_names_for_all_total", 300) do
        TotalResult.all_guild_names
      end
    end

    def guild_names_for_recently(span = nil)
      span ||= ServerSettings.result_recently_size
      return [] if span < 1
      return guild_names_for_date(date) if span == 1

      get_with_cache("guild_names_for_recently_#{span}", 300) do
        tr = TotalResult.totalize_recently_result(span)
        tr.save if tr && tr.new_record?
        tr.guild_names
      end
    end

    def guild_names_for_select(all = false)
      all ? guild_names_for_all_total : guild_names_for_recently
    end

  end
end
