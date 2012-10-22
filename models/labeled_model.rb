# coding: utf-8
module ROGv
  class LabeledModel

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

    end

  end
end