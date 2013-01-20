# coding: utf-8
module ROGv
  ROGv::Server.controllers :r do

    get :menu, :map => '/r' do
      render 'result/menu'
    end

    get :full_select, :map => '/r/full' do
      @names = guild_names_for_all_total
      render 'result/full_select'
    end

    post :full_redirect, :map => '/r/full' do
      case
      when params['for-all']
        redirect url_for(:r, :full_all)
      when params['for-guild']
        gs = parse_guild_params(params[:guild], guild_names_for_all_total)
        redirect url_for(:r, :full_select) if gs.empty?
        redirect url_for(:r, :full_guild, encode_for_url(gs.first)) if gs.size == 1
        redirect url_for(:r, :full_union, create_union_code(gs))
      else
        redirect url_for(:r, :full_select)
      end
    end

    get :full_all, :map => '/r/full/all' do
      @total = TotalResult.all_total
      render 'result/full_all'
    end

    get :full_guild, :map => '/r/full/g/:name' do
      gname = decode_for_url(params[:name])
      redirect url_for(:r, :full_select) unless guild_names_for_all_total.include?(gname)
      tr = TotalResult.all_total
      @total = tr.guild_map[gname]
      redirect url_for(:r, :full_select) unless @total
      @timelines = tr.result_timeline_for(gname, params[:all])
      render 'result/full_guild'
    end

    get :full_union, :map => '/r/full/u/:code' do
      @gnames = parse_union_code(params[:code], guild_names_for_all_total)
      redirect url_for(:r, :full_select) if @gnames.empty?
      redirect url_for(:r, :full_guild,  encode_for_url(@gnames.first)) if @gnames.size == 1
      @guilds = @gnames.inject([]){|l, n| l << TotalResult.all_total.guild_map[n]; l}
      @total = @guilds.inject(GuildResult.new){|t, g| t.add_result(g); t}
      render 'result/full_union'
    end

    get :recently_select, :map => '/r/recently' do
      @names = guild_names_for_all_total
      render 'result/recently_select'
    end

    post :recently_redirect, :map => '/r/recently' do
      case
      when params['for-all']
        num = params['week-all'].to_i
        redirect url_for(:r, :recently_select) unless valid_result_size?(num)
        redirect url_for(:r, :recently_all, num)
      when params['for-guild']
        num = params['week-guild'].to_i
        redirect url_for(:r, :recently_select) unless valid_result_size?(num)
        gs = parse_guild_params(params[:guild], guild_names_for_all_total)
        redirect url_for(:r, :recently_select) if gs.empty?
        redirect url_for(:r, :recently_guild, num, encode_for_url(gs.first)) if gs.size == 1
        redirect url_for(:r, :recently_union, num, create_union_code(gs))
      else
        redirect url_for(:r, :recently_select)
      end
    end

    get :recently_unknown, :map => '/r/recently/:num/?' do
      num = params[:num].to_i
      redirect url_for(:r, :recently_select) unless valid_result_size?(num)
      redirect url_for(:r, :recently_all, num)
    end

    get :recently_all, :map => '/r/recently/:num/all' do
      num = params[:num].to_i
      redirect url_for(:r, :recently_all, result_recently_size_default) unless valid_result_size?(num)
      @total = TotalResult.totalize_recently_result(num)
      redirect url_for(:r, :recently_select) unless @total
      @total.save if @total.new_record? && use_db_cache?
      render 'result/recently_all'
    end

    get :recently_guild, :map => '/r/recently/:num/g/:name' do
      gname = decode_for_url(params[:name])
      redirect url_for(:r, :recently_select) unless guild_names_for_all_total.include?(gname)
      num = params[:num].to_i
      redirect url_for(:r, :recently_guild, result_recently_size_default, encode_for_url(gname)) unless valid_result_size?(num)

      tr = TotalResult.totalize_recently_result(num)
      redirect url_for(:r, :recently_select) unless tr
      tr.save if tr.new_record? && use_db_cache?
      @total = tr.guild_map[gname] || GuildResult.new(:name => gname)
      @timelines = tr.result_timeline_for(gname, params[:all]) || []
      render 'result/recently_guild'
    end

    get :recently_union, :map => '/r/recently/:num/u/:code' do
      num = params[:num].to_i
      redirect url_for(:r, :recently_union, result_recently_size_default, params[:code]) unless valid_result_size?(num)
      @gnames = parse_union_code(params[:code], guild_names_for_all_total)
      redirect url_for(:r, :recently_select) if @gnames.empty?
      redirect url_for(:r, :recently_guild,  encode_for_url(@gnames.first)) if @gnames.size == 1

      tr = TotalResult.totalize_recently_result(num)
      redirect url_for(:r, :recently_select) unless tr
      tr.save if tr.new_record? && use_db_cache?
      @guilds = @gnames.inject([]){|l, n| l << (tr.guild_map[n] || GuildResult.new(:name => n)); l}
      @total = @guilds.inject(GuildResult.new){|t, g| t.add_result(g); t}
      render 'result/recently_union'
    end

    get :span_select, :map => '/r/span' do
      @dlist = result_dates
      @names = guild_names_for_all_total
      render 'result/span_select'
    end

    post :span_redirect, :map => '/r/span' do
      case
      when params['for-all']
        from = params['span-from-all']
        to = params['span-to-all']
        redirect url_for(:r, :span_select) unless exist_result_gvdates_pair?(from, to)
        redirect url_for(:r, :span_all, *([from, to].sort))
      when params['for-guild']
        from = params['span-from-guild']
        to = params['span-to-guild']
        redirect url_for(:r, :span_select) unless exist_result_gvdates_pair?(from, to)
        gs = parse_guild_params(params[:guild], guild_names_for_all_total)
        redirect url_for(:r, :span_select) if gs.empty?
        redirect url_for(:r, :span_guild, *([from, to].sort), encode_for_url(gs.first)) if gs.size == 1
        redirect url_for(:r, :span_union, *([from, to].sort), create_union_code(gs))
      else
        redirect url_for(:r, :span_select)
      end
    end

    get :span_unknown, :map => '/r/span/:from-:to/?' do
      from = params[:from]
      to = params[:to]
      redirect url_for(:r, :span_select) unless exist_result_gvdates_pair?(from, to)
      redirect url_for(:r, :span_all, *([from, to].sort))
    end

    get :span_all, :map => '/r/span/:from-:to/all' do
      from = params[:from]
      to = params[:to]
      redirect url_for(:r, :span_select) unless exist_result_gvdates_pair?(from, to)
      redirect url_for(:r, :span_all, to, from) if from > to
      dlist = result_dates.select{|d| d >= from}.select{|d| d <= to}
      redirect url_for(:r, :span_select) unless valid_result_size?(dlist.size)

      @total = TotalResult.totalize_for_dates(dlist)
      @total.save if @total.new_record? && use_db_cache?
      render 'result/span_all'
    end

    get :span_guild, :map => '/r/span/:from-:to/g/:name' do
      gname = decode_for_url(params[:name])
      redirect url_for(:r, :span_select) unless guild_names_for_all_total.include?(gname)

      from = params[:from]
      to = params[:to]
      redirect url_for(:r, :span_select) unless exist_result_gvdates_pair?(from, to)
      redirect url_for(:r, :span_guild, to, from, encode_for_url(gname)) if from > to
      dlist = result_dates.select{|d| d >= from}.select{|d| d <= to}
      redirect url_for(:r, :span_select) unless valid_result_size?(dlist.size)

      tr = TotalResult.totalize_for_dates(dlist)
      redirect url_for(:r, :span_select) unless tr
      tr.save if tr.new_record? && use_db_cache?
      @dates = tr.gv_dates
      @total = tr.guild_map[gname] || GuildResult.new(:name => gname)
      @timelines = tr.result_timeline_for(gname, params[:all]) || []
      render 'result/span_guild'
    end

    get :span_union, :map => '/r/span/:from-:to/u/:code' do
      from = params[:from]
      to = params[:to]
      redirect url_for(:r, :span_select) unless exist_result_gvdates_pair?(from, to)
      redirect url_for(:r, :span_union, to, from, params[:code]) if from > to
      dlist = result_dates.select{|d| d >= from}.select{|d| d <= to}
      redirect url_for(:r, :span_select) unless valid_result_size?(dlist.size)

      @gnames = parse_union_code(params[:code], guild_names_for_all_total)
      redirect url_for(:r, :span_select) if @gnames.empty?
      redirect url_for(:r, :span_guild, from, to, encode_for_url(@gnames.first)) if @gnames.size == 1

      tr = TotalResult.totalize_for_dates(dlist)
      redirect url_for(:r, :span_select) unless tr
      tr.save if tr.new_record? && use_db_cache?
      @dates = tr.gv_dates
      @guilds = @gnames.inject([]){|l, n| l << (tr.guild_map[n] || GuildResult.new(:name => n)); l}
      @total = @guilds.inject(GuildResult.new){|t, g| t.add_result(g); t}
      render 'result/span_union'
    end

    get :forts_date_list, :map => '/r/forts' do
      @dates = result_dates
      render 'result/forts_date_list'
    end

    get :forts_result, :map => '/r/forts/:date' do
      @result = WeeklyResult.for_date(params[:date])
      redirect url_for(:r, :forts_date_list) unless @result
      render 'result/forts_result'
    end

    get :rulers, :map => '/r/rulers' do
      redirect url_for(:r, :menu)
    end

    get :rulers, :map => '/r/rulers/:fort' do
      @rulers = FortResult.results_for(params[:fort])
      redirect url_for(:r, :menu) unless @rulers
      render 'result/rulers'
    end

  end
end
