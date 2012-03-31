# coding: utf-8
module ROGv
  class Situation
    include MongoMapper::Document

    key :revision,    String, :required => true
    key :gv_date,     String, :required => true
    key :update_time, Time,   :required => true
    many :forts, :class_name => 'ROGv::Fort'
    timestamps!
    ensure_index :revision
    ensure_index :gv_date

    scope :for_date, lambda{|d| where(:gv_date => d)}
    scope :before_revisions_for, lambda{|r| where(:revision.lt => r).order(:revision.desc)}
    scope :after_revisions_for, lambda{|r| where(:revision.gt => r).order(:revision.asc)}

    class << self
      def latest
        self.sort(:created_at.desc).limit(1).first
      end

      def date_list
        self.sort(:gv_date.desc).fields(:gv_date).map(&:gv_date).uniq
      end

      def date_before(base, diff = 1)
        return unless base
        return if diff.to_i < 1
        bd = self.where(:gv_date.lt => base).order(:gv_date.desc).skip(diff-1).limit(1).fields(:gv_date).first
        bd ? bd.gv_date : nil
      end

      def date_after(base, diff = 1)
        return unless base
        return if diff.to_i < 1
        ad = self.where(:gv_date.gt => base).order(:gv_date.asc).skip(diff-1).limit(1).fields(:gv_date).first
        ad ? ad.gv_date : nil
      end

      def revision_before(rev, diff = 1)
        return unless rev
        return if diff.to_i < 1
        before_revisions_for(rev).skip(diff-1).limit(1).first
      end

      def revision_after(rev, diff = 1)
        return unless rev
        return if diff.to_i < 1
        after_revisions_for(rev).skip(diff-1).limit(1).first
      end

      def guild_names_for(date)
        return unless date
        self.for_date(date).map(&:forts).flatten.map(&:guild_name).uniq.sort
      end

      def update_from(data)
        return if (data.nil? || data.empty?)
        utime = data.delete('update_time')
        return unless utime
        time = Time.parse(utime)

        ldata = self.latest || self.new
        return if (ldata.update_time && ldata.update_time > time)
        forts = ldata.forts_map

        si = self.new
        si.set_time(time)
        si.forts = []

        update = false
        data.each do |k, d|
          udata = Fort.create_from_data(d)
          f = forts[k]
          si.forts << if f
            f.changed?(udata) ? udata : f
          else
            udata
          end
          update = true if si.forts.include?(udata)
        end

        si.save! if update
        si
      end
    end

    def forts_map
      return {} unless (forts && !forts.empty?)
      forts.inject({}){|h, f| h[f.fort_id] = f;h}
    end

    def set_time(t)
      self.update_time = t
      set_gv_date(t)
      set_revision(t)
    end

    def set_gv_date(t)
      return unless t
      d = t.to_datetime
      self.gv_date = format("%04d%02d%02d", d.year, d.month, d.day)
    end

    def set_revision(t)
      return unless t
      d = t.to_datetime
      self.revision = format(
        "%04d%02d%02d%02d%02d%02d",
        d.year, d.month, d.day, d.hour, d.min, d.sec)
    end

    def before(diff = 1)
      return if diff.to_i < 1
      self.class.for_date(self.gv_date).before_revisions_for(self.revision).skip(diff-1).limit(1).first
    end

    def after(diff = 1)
      return if diff.to_i < 1
      self.class.for_date(self.gv_date).after_revisions_for(self.revision).skip(diff-1).limit(1).first
    end

    def leave!
      be = self.class.revision_before(self.revision)
      af = self.class.revision_after(self.revision)

      case
      when be && af
        be.connect!(af)
      when be.nil? && af
        af.forts.each{|f| f.update_time = af.update_time}
        af.save!
      when af.nil?
        # do nothing (self is last or self only)
      end
      self.destroy
    end

    def connect!(a)
      afm = a.forts_map
      bfm = self.forts_map

      [bfm.keys, afm.keys].flatten.uniq.each do |id|
        bf = bfm[id]
        af = afm[id]
        next unless af
        af.update_time = if bf
          bf.changed?(af) ? a.update_time : bf.update_time
        else
          a.update_time
        end
      end

      a.save!
    end

  end
end
