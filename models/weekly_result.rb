# coding: utf-8
module ROGv
  class WeeklyResult
    include MongoMapper::Document
    include TimeUtil
    include FortUtil

    key  :gv_date,     String, :required => true
    key  :guild_names, Array,  :required => true
    key  :source,      String
    many :guilds, :class_name => 'ROGv::GuildResult'
    many :forts,  :class_name => 'ROGv::Fort'
    timestamps!
    ensure_index :gv_date

    class << self
      def analyze_for(date)
        return unless date
        wr = self.new
        return unless wr.analyze_for(date)
        wr
      end

      def date_list
        self.sort(:gv_date.desc).fields(:gv_date).map(&:gv_date)
      end

      def for_date(d)
        self.where(:gv_date => d).first
      end

      def analyze_all!(params = nil)
        params ||= {}
        force = params[:force]
        from = params[:from]
        to = params[:to]
        dlist = Situation.date_list
        dlist = dlist.select{|d| d >= from} if from
        dlist = dlist.select{|d| d <= to} if to

        done = []
        dlist.each do |d|
          old = for_date(d)
          if old
            (force && old.analyzed?) ? old.destroy : next
          end

          wr = analyze_for(d)
          wr.save! if wr
          done << d
        end
        done
      end

      def manuals
        self.where(:source => 'manual').sort(:gv_date.desc)
      end
    end

    def analyze_for(date)
      return unless date
      ftl = FortTimelineBuilder.build_for(date)
      return unless ftl

      called = analyze_called(ftl)
      return if called.nil? || called.empty?
      ruled = analyze_ruled(ftl)
      return if ruled.nil? || ruled.empty?

      guilds = []
      called.each do |name, counts|
        g = GuildResult.new
        g.name = name
        g.gv_date = date
        g.called = counts
        r = ruled[name]
        g.ruled = r if r
        guilds << g
      end
      return if guilds.empty?

      self.gv_date = date
      self.guilds = guilds.sort_by(&:score).reverse
      self.guild_names = self.guilds.map(&:name)
      self.forts = ftl.result.values
      self
    end

    def guild_map
      self.guilds.to_a.inject({}){|h, g| h[g.name] = g; h}
    end

    def forts_map
      return {} unless (forts && !forts.empty?)
      forts.inject({}){|h, f| h[f.fort_id] = f;h}
    end

    def before
      date = self.class.date_list.select{|d| d < self.gv_date}.sort.last
      return unless date
      self.class.for_date(date)
    end

    def after
      date = self.class.date_list.select{|d| d > self.gv_date}.sort.first
      return unless date
      self.class.for_date(date)
    end

    def manual?
      self.source == 'manual' ? true : false
    end

    def analyzed?
      self.source.blank?
    end

    def parse_manual_inputs(inputs)
      return if inputs.blank?
      return unless manual?

      # fort names
      other = WeeklyResult.where(:source => nil).limit(1).first
      org_forts = other ? other.forts_map : {}

      # forts
      forts = []
      ruled = {}
      time = Time.parse("#{self.gv_date}T22:00:00+09:00")
      inputs.each do |fort, nums|
        nums.each do |num, name|
          next if name.blank?
          fort_id = "#{fort}#{num}"
          org = org_forts[fort_id]

          f = Fort.new
          f.fort_id = fort_id
          f.fort_name = org ? org.fort_name : ''
          f.formal_name = org ? org.formal_name : ''
          f.guild_name = name
          f.update_time = time
          forts << f

          ruled[name] ||= Hash.new(0)
          ruled[name][fort] += 1
        end
      end

      # guilds
      # ruled => 砦数 called => なし
      guilds = []
      ruled.each do |gname, h|
        g = GuildResult.new
        g.name = gname
        g.gv_date = self.gv_date
        g.called = {}
        g.ruled = Hash[h]
        guilds << g
      end

      self.forts = forts
      self.guilds = guilds.sort_by(&:score).reverse
      self.guild_names = self.guilds.map(&:name)

      self
    end

    private

    def analyze_called(ftl)
      return unless ftl
      called = {}
      fort_types.each do |f|
        ftl.each_changed_time(fort_ids_for(f)) do |time, list|
          list.each do |name|
            case name
            when Symbol
              next
            when String
              called[name] ||= Hash.new(0)
              called[name][f] += 1
            end
          end
        end
      end
      called.each{|k, v| called[k] = Hash[v]}
    end

    def analyze_ruled(ftl)
      return unless ftl
      rsl = {}
      ftl.result.each do |fid, fort|
        next unless fort
        gname = fort.guild_name
        rsl[gname] ||= Hash.new(0)
        rsl[gname][fid[0]] += 1
      end
      rsl.each{|k, v| rsl[k] = Hash[v]}
    end

  end
end
