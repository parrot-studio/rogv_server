# coding: utf-8
module ROGv
  class GuildResult
    include MongoMapper::EmbeddedDocument
    include FortUtil

    key :name,    String, :required => true
    key :gv_date, String
    key :called,  Hash,   :required => true
    key :ruled,   Hash,   :required => true

    def called_count_fe
      @called_count_fe ||= self.called.inject(0){|r, h| r += h.last if fort_types_fe?(h.first); r}
      @called_count_fe
    end

    def called_count_se
      @called_count_se ||= self.called.inject(0){|r, h| r += h.last if fort_types_se?(h.first); r}
      @called_count_se
    end

    def called_count_te
      @called_count_te ||= self.called.inject(0){|r, h| r += h.last if fort_types_te?(h.first); r}
      @called_count_te
    end

    def called_count
      called_count_fe + called_count_se + called_count_te
    end

    def ruled_count_fe
      @ruled_count_fe ||= self.ruled.inject(0){|r, h| r += h.last if fort_types_fe?(h.first); r}
      @ruled_count_fe
    end

    def ruled_count_se
      @ruled_count_se ||= self.ruled.inject(0){|r, h| r += h.last if fort_types_se?(h.first); r}
      @ruled_count_se
    end

    def ruled_count_te
      @ruled_count_te ||= self.ruled.inject(0){|r, h| r += h.last if fort_types_te?(h.first); r}
      @ruled_count_te
    end

    def ruled_count
      ruled_count_fe + ruled_count_se + ruled_count_te
    end

    def has_forts?
      ruled_count > 0 ? true : false
    end

    def score
      @score ||= score_for_order_list(
        :ruled_count, :ruled_count_se, :ruled_count_fe, :ruled_count_te,
        :called_count, :called_count_se, :called_count_fe, :called_count_te)
      @score
    end

    def score_for_fe
      @score_for_fe ||= score_for_order_list(
        :ruled_count_fe, :ruled_count, :ruled_count_se, :ruled_count_te,
        :called_count_fe, :called_count, :called_count_se, :called_count_te)
      @score_for_fe
    end

    def score_for_se
      @score_for_se ||= score_for_order_list(
        :ruled_count_se, :ruled_count, :ruled_count_fe, :ruled_count_te,
        :called_count_se, :called_count, :called_count_fe, :called_count_te)
      @score_for_se
    end

    def score_for_te
      @score_for_te ||= score_for_order_list(
        :ruled_count_te, :ruled_count, :ruled_count_se, :ruled_count_fe,
        :called_count_te, :called_count, :called_count_se, :called_count_fe)
      @score_for_te
    end
    
    def add_result(g)
      self.called = merge_result(self.called, g.called)
      self.ruled = merge_result(self.ruled, g.ruled)
      self
    end

    private

    def merge_result(org, add)
      keys = [org.keys, add.keys].flatten.uniq.compact
      rsl = {}
      keys.each do |f|
        rsl[f] = org[f].to_i + add[f].to_i
      end
      rsl
    end

    def score_for_order_list(*list)
      return 0 if list.nil? || list.empty?
      times = 0
      score = 0
      [list].flatten.reverse.each do |m|
        score += self.__send__(m) * 10**times
        times += 4
      end
      score
    end

  end
end
