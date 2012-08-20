# coding: utf-8
module ROGv
  class TotalResult
    include MongoMapper::Document
    include TimeUtil

    key  :label,       String, :required => true
    key  :gv_dates,    Array,  :required => true
    key  :guild_names, Array,  :required => true
    many :guilds, :class_name => 'ROGv::GuildResult'
    timestamps!
    ensure_index :label

    TOTAL_LABEL_ALL = 'all'

    class << self
      def get_and_remove_for_label(l)
        return unless l
        exists = self.where(:label => l).order(:updated_at.desc).to_a
        # 同じlabelで複数あった場合、最新を残して消去
        tr = exists.shift
        exists.each(&:destroy) unless exists.empty?
        tr
      end
      alias :for_label :get_and_remove_for_label

      def all_total
        tr = self.for_label(TOTAL_LABEL_ALL)
        tr ||= lambda do
          t = self.new
          t.label = TOTAL_LABEL_ALL
          t
        end.call
        tr
      end

      def add_result_to_all_total!(d)
        tr = self.all_total.add_result(d)
        tr.save! if tr
        tr
      end

      def totalize_recently_result(span, from = nil)
        return if span.nil? || span <= 0
        totalize_for_dates(target_dates_of_recently(span, from))
      end

      def totalize_for_dates(dates)
        return if dates.nil? || dates.empty?

        label = create_label_from_dates(dates)
        tr = self.for_label(label)
        return tr if tr

        tr = self.new
        tr.label = label
        dates.each {|d| tr.add_result(d)}
        tr
      end

      def create_label_from_dates(dates)
        return if dates.nil? || dates.empty?
        case dates.size
        when 1
          dates.first
        else
          ds = dates.sort
          "#{ds.first}-#{ds.last}"
        end
      end

      def all_guild_names
        all_total.guild_names
      end

      def caches
        self.all.reject{|t| t.label == TOTAL_LABEL_ALL}
      end

      private

      def target_dates_of_recently(span, from = nil)
        return [] if span.nil? || span <= 0
        if from
          WeeklyResult.date_list.select{|d| d <= from}
        else
          WeeklyResult.date_list
        end.sort.reverse.take(span)
      end
    end

    def guild_map
      self.guilds.to_a.inject({}){|h, g| h[g.name] = g; h}
    end

    def add_result(d)
      return self if self.gv_dates.include?(d)

      wr = WeeklyResult.for_date(d)
      return unless wr

      wr.guilds.each do |wrg|
        trg = self.guilds.to_a.find{|g| g.name == wrg.name}
        trg ? trg.add_result(wrg) : (self.guilds << wrg.dup)
      end

      self.gv_dates = [self.gv_dates, d].flatten.sort.reverse
      self.guilds = self.guilds.sort_by(&:score).reverse
      self.guilds.each{|g| g.gv_date = nil}
      self.guild_names = self.guilds.map(&:name)

      self
    end

    def result_timeline_for(gname, all = false)
      return if gname.nil? || gname.empty?
      return if self.gv_dates.empty?
      return unless guild_names.include?(gname)

      self.gv_dates.map do |d|
        g = WeeklyResult.for_date(d).guild_map[gname]
        g ||= GuildResult.new if all
        g.gv_date = d if g
        g
      end.compact
    end

  end
end
