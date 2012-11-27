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

    def revision_to_formet_time(rev)
      return unless rev
      "#{rev[0..3]}/#{rev[4..5]}/#{rev[6..7]} #{rev[8..9]}:#{rev[10..11]}:#{rev[12..13]}"
    end

    def revision_to_format_time_only(rev)
      return unless rev
      "#{rev[8..9]}:#{rev[10..11]}:#{rev[12..13]}"
    end

    def in_battle_time?(t = nil)
      t ||= DateTime.now
      return false unless t.sunday?
      return false if t < DateTime.new(t.year, t.mon, t.mday, 19, 50, 0)
      return false if t  > DateTime.new(t.year, t.mon, t.mday, 22, 10, 0)
      true
    end

    def shift_gvdate(gd, diff)
      return unless (gd && diff)
      d = Date.new(gd[0..3].to_i, gd[4..5].to_i, gd[6..7].to_i) + diff
      format("%04d%02d%02d", d.year, d.month, d.day)
    end

    def before_gvdate(gd)
      shift_gvdate(gd, -7)
    end

    def after_gvdate(gd)
      shift_gvdate(gd, 7)
    end

    def valid_gvdate?(d)
      return false unless d
      d.match(/\A\d{8}\z/) ? true : false
    end

  end
end
