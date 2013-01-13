# coding: utf-8
module ROGv
  class FortTimeline < LabeledModel
    include MongoMapper::Document

    key :label,   String, :required => true
    key :gv_date, String, :required => true
    key :forts,   Array,  :required => true
    key :revs,    Array,  :required => true
    key :before_states, Hash, :required => true
    key :states,  Hash, :required => true
    key :results, Hash, :required => true
    timestamps!
    ensure_index :label

    class << self
      def get_for(date, *forts)
        return unless date
        targets = target_from_forts(forts)
        return if targets.empty?

        label = create_label(date, targets)
        stored = self.for_label(label)
        stored ? stored : build_for(date, forts)
      end

      def build_for(date, *forts)
        return unless date
        targets = target_from_forts(forts)
        return if targets.empty?

        ftl = FortTimelineBuilder.build_for(date)
        return unless ftl

        before = targets.inject({}) do |h, t|
          f = ftl.before_date_fort(t)
          h[t] = f ? f.guild_name : ''
          h
        end

        results = targets.inject({}) do |h, t|
          f = ftl.result_for(t)
          h[t] = f ? f.guild_name : ''
          h
        end

        states = {}
        ftl.each_changed_time(targets, true) do |time, list|
          states[TimeUtil.time_to_revision(time)] = targets.zip(list).inject({}){|h,d| h[d.first] = d.last;h}
        end

        ft = self.new
        ft.label = create_label(date, targets)
        ft.gv_date = date
        ft.forts = targets
        ft.revs = ftl.times.map{|t| TimeUtil.time_to_revision(t)}
        ft.before_states = before
        ft.states = states
        ft.results = results

        ft
      end

      def create_label(date, forts)
        return if (date.nil? || forts.nil? || forts.empty?)
        "#{date}_#{forts.sort.join('')}"
      end

      def caches
        self.all
      end

      def cache_clear!
        self.caches.each(&:destroy)
      end

      private

      def target_from_forts(forts)
        flist = [forts].flatten.compact.uniq.select{|f| FortUtil.fort_types?(f)}
        flist.map{|f| FortUtil.fort_ids_for(f)}.flatten
      end
    end

    def each_changed_time(all = false)
      self.states.each do |rev, datas|
        next if !all && datas.values.all?{|s| s == :stay}
        yield(rev, datas)
      end
    end

  end
end
