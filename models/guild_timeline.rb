# coding: utf-8
module ROGv
  class GuildTimeline < LabeledModel
    include MongoMapper::Document

    key :label,   String, :required => true
    key :gv_date, String, :required => true
    key :guilds,  Array,  :required => true
    key :revs,    Array,  :required => true
    key :before_states, Hash
    key :states,  Hash, :required => true
    key :results, Hash
    timestamps!
    ensure_index :label

    class << self
      def build_for(date, *guilds)
        return unless date
        glist = [guilds].flatten.compact.uniq.sort
        return if glist.empty?

        label = create_label(date, glist)
        stored = self.for_label(label)
        return stored if stored

        gtl = GuildTimelineBuilder.build_for(date, glist)
        return unless gtl

        before = FortUtil.each_fort_id.inject({}) do |h, fid|
          next h unless gtl.initial_owner?(fid)
          h[fid] = gtl.initial_owner(fid)
          h
        end

        results = FortUtil.each_fort_id.inject({}) do |h, fid|
          next h unless gtl.final_owner?(fid)
          h[fid] = gtl.final_owner(fid)
          h
        end

        states = {}
        gtl.each_changed_time(true) do |time, h|
          rsl = {}
          h.each do |fid, state|
            next unless state
            rsl[fid] = state
          end
          states[TimeUtil.time_to_revision(time)] = rsl
        end

        gt = self.new
        gt.label = label
        gt.gv_date = date
        gt.guilds = glist
        gt.revs = gtl.times.map{|t| TimeUtil.time_to_revision(t)}
        gt.before_states = before
        gt.states = states
        gt.results = results

        gt
      end

      def create_label(date, guilds)
        return if (date.nil? || guilds.nil? || guilds.empty?)
        "#{date}_:_#{guilds.sort.join("_-_")}"
      end

      def caches
        self.all
      end

      def cache_clear!
        self.caches.each(&:destroy)
      end
    end

    def each_changed_time(all = false)
      self.states.each do |rev, datas|
        next if !all && (datas.empty? || datas.values.all?{|s| s == :stay})
        yield(rev, datas)
      end
    end

  end
end
