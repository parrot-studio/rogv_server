# coding: utf-8
module ROGv
  module FortUtil

    module_function

    def fort_types
      [fort_types_fe, fort_types_se].flatten
    end

    def fort_types_fe
      ['V', 'C', 'B', 'L']
    end

    def fort_types_se
      ['N', 'F']
    end

    def fort_nums
      (1..5).to_a
    end

    def fort_types?(t)
      return false unless t
      fort_types.include?(t) ? true : false
    end

    def fort_types_fe?(t)
      return unless t
      fort_types_fe.include?(t) ? true : false
    end

    def fort_types_se?(t)
      return unless t
      fort_types_se.include?(t) ? true : false
    end

    def exist_fort?(t)
      return false unless t
      m = t.match(/\A(.)(\d)\Z/)
      return false unless m
      return false unless fort_types?(m[1])
      return false unless fort_nums.include?(m[2].to_i)
      true
    end

    def each_fort_id
      return enum_for(:each_fort_id) unless block_given?
      fort_types.each do |ft|
        fort_nums.each do |n|
          yield("#{ft}#{n}")
        end
      end
    end

    def fort_ids_for(f)
      return [] unless fort_types?(f)
      fort_nums.map{|i| "#{f}#{i}"}
    end

    def fort_ids_for_se
      fort_types_se.map{|f| fort_ids_for(f)}.flatten
    end

  end
end
