# coding: utf-8
require 'fileutils'

module ROGv
  class Command

    attr_reader :result

    def self.execute(cmd)
      return if cmd.nil? || cmd.empty?
      self.new.execute(cmd)
    end

    def execute(cmd)
      return if cmd.nil? || cmd.empty?
      @result = %x(#{cmd})
      @exit_status = $?
      self
    end

    def exit_status_code
      @exit_status.exitstatus
    end

    def has_error?
      exit_status_code != 0 ? true : false
    end
  end

  class Dumper
    include TimeUtil

    class << self
      def dump_path
        File.expand_path(File.join(PADRINO_ROOT, 'dump'))
      end

      def execute
        self.new.execute
      end
    end

    def dump_path
      self.class.dump_path
    end

    def dump_time
      @dump_time ||= DateTime.now
      @dump_time
    end

    def dump_name
      "dump_#{time_to_revision(dump_time)}"
    end

    def dump_output_path
      File.join(dump_path, dump_name)
    end

    def archive_file_name
      "#{dump_name}.tar.gz"
    end

    def archive_file_path
      File.join(dump_path, archive_file_name)
    end

    def dump
      FileUtils.mkdir_p(dump_path) unless File.exist?(dump_path)
      FileUtils.rm_r(dump_output_path) if File.exist?(dump_output_path)
      cmd = "mongodump -d #{ServerSettings.db.name} -o #{dump_output_path}"
      if (ServerSettings.db.user && ServerSettings.db.pass)
        cmd << " -u #{ServerSettings.db.user} -p #{ServerSettings.db.pass}"
      end
      rsl = Command.execute(cmd)
      raise "dump error => #{rsl.result}" if rsl.has_error?
      raise "dump missing" unless File.exist?(dump_output_path)
      self
    end

    def archive
      File.unlink(archive_file_path) if File.exist?(archive_file_path)
      return self unless File.exist?(dump_output_path)
      cmd = "cd #{dump_path}; tar czf #{archive_file_name} ./#{dump_name}"
      rsl = Command.execute(cmd)
      raise "archive error => #{rsl.result}" if rsl.has_error?
      raise "archive missing" unless File.exist?(archive_file_path)
      FileUtils.rm_r(dump_output_path) if File.exist?(dump_output_path)
      self
    end

    def execute
      dump.archive
    end
  end

  class DumpFile

    attr_reader :filename, :revision

    class << self
      def find_by_filename(fn)
        return unless fn
        df = self.new
        df.set_filename(fn)
        df.exist? ? df : nil
      end

      def find_by_revision(rev)
        return unless rev
        df = self.new
        df.set_revision(rev)
        df.exist? ? df : nil
      end

      def all
        Dir.glob("#{Dumper.dump_path}/dump_*").map{|fn| self.find_by_filename(fn)}.compact
      end
    end

    def set_filename(fn)
      f = File.basename(fn)
      return if f.nil? || f.empty?
      @filename = f
      @revision = f[/\Adump_(\d+)/, 1]
      self
    end

    def set_revision(rev)
      return unless rev
      @revision = rev
      @filename = "dump_#{rev}.tar.gz"
      self
    end

    def full_path
      return if filename.nil? || filename.empty?
      File.join(Dumper.dump_path, filename)
    end

    def exist?
      return false if filename.nil? || filename.empty?
      return false if revision.nil? || revision.empty?
      File.exist?(full_path) ? true : false
    end

    def delete!
      return unless exist?
      File.unlink(full_path)
      self
    end
  end
end
