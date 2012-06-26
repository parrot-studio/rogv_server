# coding: utf-8
module ROGv
  ROGv::Server.helpers do
    include TimeUtil

    def reload_cycle
      ['30', '60', '120']
    end

    def sample_mode?
      ServerConfig.auth_sample_mode ? true : false
    end

    def updatable_mode?
      return false if sample_mode?
      ServerConfig.auth_view_mode ? false : true
    end

    def fort_types
      ['V', 'C', 'B', 'L', 'N', 'F']
    end

    def fort_nums
      (1..5).to_a
    end

    def fort_types?(t)
      return false unless t
      fort_types.include?(t) ? true : false
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

    def encode_for_url(s)
      URI.encode_www_form_component(s).gsub("+", "%20")
    end

    def render_fort_table(s)
      partial :forts_table, :object => @situation
    end

  end
end