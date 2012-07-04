# coding: utf-8
require 'date'

module ROGv
  module TimeUtil

    module_function

    def to_jst_datetime(t)
      return unless t
      (t.utc? ? t + Time.now.utc_offset : t).to_datetime
    end

    def format_time(t)
      return unless t
      d = to_jst_datetime(t)
      format("%04d/%02d/%02d %02d:%02d:%02d",
        d.year, d.month, d.day, d.hour, d.min, d.sec)
    end

    def format_time_only(t)
      return unless t
      d = to_jst_datetime(t)
      format("%02d:%02d:%02d", d.hour, d.min, d.sec)
    end

    def devided_date(ds)
      return unless ds
      "#{ds[0..3]}/#{ds[4..5]}/#{ds[6..7]}"
    end

    def time_to_revision(t)
      return unless t
      d = to_jst_datetime(t)
      format("%04d%02d%02d%02d%02d%02d",
        d.year, d.month, d.day, d.hour, d.min, d.sec)
    end

    def time_to_gvdate(t)
      return unless t
      d = to_jst_datetime(t)
      format("%04d%02d%02d", d.year, d.month, d.day)
    end

    def in_battle_time?(t = nil)
      t ||= DateTime.now
      return false unless t.sunday?
      return false unless (19..22).include?(t.hour)
      true
    end

  end
end
