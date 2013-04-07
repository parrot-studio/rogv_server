# coding: utf-8
require 'fileutils'

module ROGv
  class Exporter

    attr_accessor :start_date, :end_date

    def execute
      FileUtils.mkdir_p(export_path) unless File.exist?(export_path)
      execute_for_situations
      execute_for_manuals
      self
    end

    private

    def execute_for_situations
      dates = Situation.date_list
      dates = dates.select{|d| d >= self.start_date} if self.start_date
      dates = dates.select{|d| d <= self.end_date} if self.end_date
      return if dates.empty?
      dates.sort.each{|d| export_for_date(d)}
      self
    end

    def execute_for_manuals
      manuals = WeeklyResult.where(:source => 'manual')
      return unless manuals
      file = export_file('manual')
      File.unlink(file) if File.exist?(file)
      File.open(file, 'w') do |f|
        manuals.each do |wr|
          f.puts(serialize_for_result(wr))
        end
      end
      self
    end

    def export_path
      File.expand_path(File.join(PADRINO_ROOT, 'dump', 'export'))
    end

    def export_file(name)
      File.expand_path(File.join(export_path, "#{name}.txt"))
    end

    def export_for_date(date)
      return unless date
      ss = Situation.for_date(date)
      return if ss.empty?

      file = export_file(date)
      File.unlink(file) if File.exist?(file)
      File.open(file, 'w') do |f|
        ss.sort_by(&:revision).each do |s|
          f.puts(serialize_for_situation(s))
        end
      end

      file
    end

    def serialize_for_situation(s)
      return unless s

      ret = {}
      ret['gv_date'] = s.gv_date
      ret['revision'] = s.revision
      ret['update_time'] = s.update_time

      ret['forts'] = s.forts.map do |f|
        fd = {}
        fd['fort_id'] = f.fort_id
        fd['fort_name'] = f.fort_name
        fd['formal_name'] = f.formal_name
        fd['guild_name'] = f.guild_name
        fd['update_time'] = f.update_time
        fd
      end

      ret.to_json
    end

    def serialize_for_result(wr)
      return unless wr

      ret = {}
      ret['gv_date'] = wr.gv_date
      ret['forts'] = wr.forts.map do |f|
        fd = {}
        fd['fort_id'] = f.fort_id
        fd['guild_name'] = f.guild_name
        fd
      end

      ret.to_json
    end

  end
end
