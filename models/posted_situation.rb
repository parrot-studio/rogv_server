# coding: utf-8
module ROGv
  class PostedSituation
    include MongoMapper::Document
    include TimeUtil

    key :update_time, Time,    :required => true
    key :locked,      Boolean
    many :forts, :class_name => 'ROGv::Fort'
    timestamps!
    ensure_index :created_at

    class << self
      def next_target
        self.sort(:created_at.asc).limit(1).first
      end

      def build_from(data)
        return if (data.nil? || data.empty?)
        utime = data.delete('update_time')
        return unless utime
        time = Time.parse(utime)

        s = self.new
        s.update_time = time
        s.forts = []

        data.each do |k, d|
          f = Fort.create_from_data(d)
          s.forts << f if f
        end

        s.valid? ? s : nil
      end

      def accept(data)
        ps = build_from(data)
        return unless ps
        ps.locked = false
        ps.save!
        ps
      end
    end

    def revision
      time_to_revision(self.update_time)
    end

    def locked?
      self.locked ? true : false
    end

    def lock!
      self.locked = true
      save!
    end

    def valid?
      return false if self.forts.empty?
      self.forts.any?{|f| FortUtil.exist_fort?(f.fort_id)} ? true : false
    end
  end
end
