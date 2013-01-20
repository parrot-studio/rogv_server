# coding: utf-8
module ROGv
  ROGv::Server.helpers do

    def result_view_for_se?
      return false unless params[:priority]
      params[:priority].downcase == 'se' ? true : false
    end

    def result_view_for_fe?
      return false unless params[:priority]
      params[:priority].downcase == 'fe' ? true : false
    end

    def result_view_for_all?
      return true unless params[:priority]
      return false if (result_view_for_se? || result_view_for_fe?)
      true
    end

    def result_subtitle
      case
      when result_view_for_se?
        ' (for SE)'
      when result_view_for_fe?
        ' (for FE)'
      else
        ''
      end
    end

    def result_recently_size_default
      ServerSettings.result_recently_size
    end

    def result_range
      (ServerSettings.result_min_size..ServerSettings.result_max_size)
    end

    def valid_result_size?(n)
      return false unless n
      result_range.include?(n) ? true : false
    end

    def exist_result_gvdates_pair?(from, to)
      return false unless (from && to)
      return false unless (valid_gvdate?(from) && valid_gvdate?(to))
      return false unless (result_dates.include?(from) && result_dates.include?(to))
      true
    end

  end
end
