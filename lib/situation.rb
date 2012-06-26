# coding: utf-8
module ROGv
  class Situation
    include MongoMapper::Document
    include TimeUtil

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
        self.sort(:revision.desc).limit(1).first
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

      def apply(ps)
        return unless ps
        return if (ps.forts.nil? || ps.forts.empty?)

        ldata = self.latest || self.new
        return if (ldata.revision && ldata.revision >= ps.revision)
        forts = ldata.forts_map

        si = self.new
        si.set_time(ps.update_time)
        si.forts = []

        update = false
        ps.forts.each do |udata|
          f = forts[udata.fort_id]
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

      def update_from(data)
        apply(build_from(data))
      end

      def build_from(data)
        return if (data.nil? || data.empty?)
        utime = data.delete('update_time')
        return unless utime
        time = Time.parse(utime)

        s = self.new
        s.set_time(time)
        s.forts = []

        data.each do |k, d|
          f = Fort.create_from_data(d)
          s.forts << f if f
        end

        s.forts.empty? ? nil : s
      end

      def cut_in_from(data)
        s = build_from(data)
        return unless s
        s.cut_in!
      end
    end

    def forts_map
      return {} unless (forts && !forts.empty?)
      forts.inject({}){|h, f| h[f.fort_id] = f;h}
    end

    def set_time(t)
      return unless t
      self.update_time = t
      self.gv_date = time_to_gvdate(t)
      self.revision = time_to_revision(t)
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
      return unless a
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
      self
    end

    def cut_in!
      return if (self.forts.nil? || self.forts.empty?)
      return if Situation.find_by_revision(self.revision)

      be = self.class.revision_before(self.revision)
      af = self.class.revision_after(self.revision)
      be.connect!(self) if be
      self.connect!(af) if af

      self.save!
      self
    end

  end
end
