# coding: utf-8
require 'singleton'

module ROGv
  class Updater
    include Singleton

    class << self
      def update_form(data)
        self.instance.update_form(data)
      end
    end

    def update_form(data)
      accept(data)
      apply
    end

    private

    def accept(data)
      PostedSituation.accept(data)
    end

    def next_target
      t = PostedSituation.next_target
      return if (t.nil? || t.locked?)
      t.lock!
      t
    end

    def apply
      loop do
        ps = next_target
        break unless ps

        begin
          Situation.apply(ps)
        ensure
          ps.destroy if ps
        end
      end
    end

  end
end
