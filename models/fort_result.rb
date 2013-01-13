# coding: utf-8
module ROGv
  class FortResult < LabeledModel
    include MongoMapper::Document

    key :label,    String, :required => true
    key :fort,     String, :required => true
    key :gv_dates, Array,  :required => true
    key :rulers,   Hash,   :required => true
    timestamps!
    ensure_index :label

    class << self
      def results_for(fort)
        return unless FortUtil.fort_types?(fort)
        self.for_label("fort_result_#{fort}")
      end

      def add_result(date)
        FortUtil.fort_types.each do |fort|
          tl = FortTimeline.build_for(date, fort)
          next unless tl

          results = tl.results.dup
          next if results.empty?

          # コールがあったかを確認
          unless tl.revs.empty?
            call = {}

            before = tl.before_states.dup
            before.each do |fid, name|
              next if results[fid] == name
              call[fid] = true
            end

            tl.each_changed_time do |rev, datas|
              datas.each do |fid, name|
                next if call[fid]
                next if name == :stay
                call[fid] = true unless results[fid] == name
              end
            end

            results.keys.each do |fid|
              next if call[fid]
              results[fid] = :stay
            end
          end

          # 格納
          rsl = self.results_for(fort)
          rsl ||= lambda do
            fr = self.new
            fr.label = "fort_result_#{fort}"
            fr.fort = fort
            fr
          end.call

          rsl.gv_dates = [rsl.gv_dates, date].flatten.compact.uniq.sort
          rsl.rulers[date] = results
          rsl.save!
        end

        true
      end

      def add_manual_result(wr)
        return unless (wr && wr.manual?)
        date = wr.gv_date

        FortUtil.fort_types.each do |fort|
          # 継続情報なしで格納
          results = {}
          forts = wr.forts
          forts.each do |f|
            next unless f.fort_id.match(/\A#{fort}/)
            results[f.fort_id] = f.guild_name
          end

          rsl = self.results_for(fort)
          rsl ||= lambda do
            fr = self.new
            fr.label = "fort_result_#{fort}"
            fr.fort = fort
            fr
          end.call

          rsl.gv_dates = [rsl.gv_dates, date].flatten.compact.uniq.sort
          rsl.rulers[date] = results
          rsl.save!
        end

        true
      end
    end

  end
end
