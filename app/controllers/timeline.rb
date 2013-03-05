# coding: utf-8
module ROGv
  ROGv::Server.controllers :t do

    get :date_list, :map => '/t' do
      list = timeline_dates
      default_size = ServerSettings.result_recently_size

      @dlist = case
      when params[:all]
        list
      when params[:recently]
        size = params[:recently].to_i
        redirect url_for(:t, :date_list) if (size <= 0 || size == default_size)
        redirect url_for(:t, :date_list, :all => 1) if size > list.size
        list.take(size)
      else
        list.take(default_size)
      end

      render 'timeline/date_list'
    end

    get :date, :map => '/t/d/:date' do
      date_action do |date|
        @dlist = [date]
        render 'timeline/date_list'
      end
    end

    get :rev_list, :map => '/t/d/:date/r/?' do
      date_action do |date|
        @revs = revs_for_date(date)
        redirect url_for(:t, :date, date) if @revs.empty?
        render 'timeline/rev_list'
      end
    end

    get :rev, :map => '/t/d/:date/r/:rev' do
      date_action do |date|
        @situation = Situation.find_by_revision(params[:rev])
        redirect url_for(:t, :date, date) unless @situation
        render 'timeline/rev'
      end
    end

    delete :delete, :map => '/t/d/:date/r/:rev' do
      date_action do |date|
        rev_path = url_for(:t, :rev, date, params[:rev])
        redirect rev_path unless updatable_mode?
        redirect rev_path unless valid_delete_key?(params[:dkey])
        s = Situation.find_by_revision(params[:rev])
        s.leave! if s
        redirect url_for(:t, :rev_list, date)
      end
    end

    get :fort_timeline_unknown, '/t/d/:date/f/?' do
      date_action do |date|
        redirect url_for(:t, :date, date)
      end
    end

    get :fort_timeline, :map => '/t/d/:date/f/:fort' do
      date_action do |date|
        fort = params[:fort]
        fs = case fort
        when 'SE'
          fort_types_se
        when 'TE'
          fort_types_te
        else
          fort_types?(fort) ? fort : nil
        end

        redirect url_for(:t, :date, date) if fs.nil? || fs.empty?
        @timeline = FortTimeline.get_for(date, fs)
        redirect url_for(:t, :date, date) unless @timeline
        @timeline.save if @timeline.new_record? && use_db_cache?
        render 'timeline/fort_timeline'
      end
    end

    get :union_select, '/t/d/:date/g/?' do
      date_action do |date|
        @names = guild_names_for_date(date)
        render 'timeline/union'
      end
    end

    get :guild_timeline, :map => '/t/d/:date/g/:name' do
      date_action do |date|
        gname = decode_for_url(params[:name])
        @timeline = GuildTimeline.get_for(date, gname)
        redirect url_for(:t, :date, date) unless @timeline
        @timeline.save if @timeline.new_record? && use_db_cache?
        @names = [gname]
        render 'timeline/guild_timeline'
      end
    end

    get :union_select_unknown, :map => '/t/d/:date/u/?' do
      date_action do |date|
        redirect url_for(:t, :union_select, date)
      end
    end

    post :union_select_build, :map => '/t/d/:date/u/?' do
      date_action do |date|
        names = guild_names_for_date(date)
        gs = parse_guild_params(params[:guild], names)
        redirect url_for(:t, :union_select, date) if gs.empty?
        redirect url_for(:t, :guild_timeline, date, encode_for_url(gs.first)) if gs.size == 1
        redirect url_for(:t, :union_timeline, date, create_union_code(gs))
      end
    end

    get :union_timeline, :map => '/t/d/:date/u/:names' do
      date_action do |date|
        names = guild_names_for_date(date)
        @names = parse_union_code(params[:names], names)
        redirect url_for(:t, :union_select, date) if @names.empty?
        redirect url_for(:t, :guild_timeline, date, encode_for_url(gs.first)) if @names.size == 1
        @timeline = GuildTimeline.get_for(date, @names)
        redirect url_for(:t, :date, date) unless @timeline
        @timeline.save if @timeline.new_record? && use_db_cache?
        render 'timeline/guild_timeline'
      end
    end

    get :span_union_select, :map => '/t/span' do
      @dlist = timeline_dates
      @names = guild_names_for_all_total
      render 'timeline/span_union'
    end

    post :span_union_select_build, :map => '/t/span' do
      from = params['span-from-guild']
      to = params['span-to-guild']
      redirect url_for(:t, :span_union_select) unless exist_timeline_gvdates_pair?(from, to)
      gs = parse_guild_params(params[:guild], guild_names_for_all_total)
      redirect url_for(:t, :span_union_select) if gs.empty?
      redirect url_for(:t, :span_guild_timeline, *([from, to].sort), encode_for_url(gs.first)) if gs.size == 1
      redirect url_for(:t, :span_union_timeline, *([from, to].sort), create_union_code(gs))
    end

    get :span_guild_timeline, :map => '/t/span/:from-:to/g/:name' do
      gname = decode_for_url(params[:name])
      redirect url_for(:t, :span_union_select) unless guild_names_for_all_total.include?(gname)

      from = params[:from]
      to = params[:to]
      redirect url_for(:t, :span_union_select) unless exist_timeline_gvdates_pair?(from, to)
      redirect url_for(:t, :span_guild_timeline, to, from, params[:name]) if from > to
      @dlist = timeline_dates.select{|d| d >= from}.select{|d| d <= to}.sort
      redirect url_for(:t, :guild_timeline, @dlist.first, params[:name]) if @dlist.size == 1
      redirect url_for(:t, :span_union_select) unless valid_span_timeline_size?(@dlist.size)

      @timelines = {}
      @dlist.each do |date|
        tl = GuildTimeline.get_for(date, gname)
        next unless tl
        tl.save if tl.new_record? && use_db_cache?
        @timelines[date] = tl
      end
      redirect url_for(:t, :span_union_select) if @timelines.empty?
      @names = [gname]

      render 'timeline/span_timeline'
    end

    get :span_union_timeline, :map => '/t/span/:from-:to/u/:names' do
      from = params[:from]
      to = params[:to]
      redirect url_for(:t, :span_union_select) unless exist_timeline_gvdates_pair?(from, to)
      redirect url_for(:t, :span_union_timeline, to, from, params[:name]) if from > to
      @dlist = timeline_dates.select{|d| d >= from}.select{|d| d <= to}.sort
      redirect url_for(:t, :union_timeline, @dlist.first, params[:names]) if @dlist.size == 1
      redirect url_for(:t, :span_union_select) unless valid_span_timeline_size?(@dlist.size)

      @names = parse_union_code(params[:names], guild_names_for_all_total)
      redirect url_for(:t, :span_union_select) if @names.empty?
      redirect url_for(:t, :span_guild_timeline, from, to, encode_for_url(@names.first)) if @names.size == 1

      @timelines = {}
      @dlist.each do |date|
        tl = GuildTimeline.get_for(date, @names)
        next unless tl
        tl.save if tl.new_record? && use_db_cache?
        @timelines[date] = tl
      end
      redirect url_for(:t, :span_union_select) if @timelines.empty?

      render 'timeline/span_timeline'
    end

  end
end
