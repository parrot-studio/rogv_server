# coding: utf-8
module ROGv
  ROGv::Server.controllers  do

    get :index do
      if params[:re]
        @reload = params[:re]
        redirect url_for(:index) unless reload_cycle.include?(@reload)
      end
      @unlink = true
      @situation = Situation.latest || Situation.new
      render :index
    end

    get :date_list, :map => '/d/?' do
      @dlist = Situation.date_list
      render :date_list
    end

    get :date, :map => '/d/:date' do
      date_action do |date|
        @dlist = [date]
        render :date_list
      end
    end

    get :rev_list, :map => '/d/:date/r/?' do
      date_action do |date|
        @revs = revs_for_date(date)
        redirect url_for(:date, date) if @revs.empty?
        render :rev_list
      end
    end

    get :rev, :map => '/d/:date/r/:rev' do
      date_action do |date|
        @situation = Situation.find_by_revision(params[:rev])
        redirect url_for(:date, date) unless @situation
        render :rev
      end
    end

    get '/d/:date/f/?' do
      date_action do |date|
        redirect url_for(:date, date)
      end
    end

    get :fort_timeline_se, :map => '/d/:date/f/SE' do
      date_action do |date|
        @targets = []
        ['N', 'F'].each do |t|
          fort_nums.each{|i| @targets << "#{t}#{i}"}
        end
        @timeline = FortTimeline.build_for(date)
        redirect url_for(:date, date) unless @timeline
        render :fort_timeline
      end
    end

    get :fort_timeline, :map => '/d/:date/f/:fort' do
      date_action do |date|
        fort = params[:fort]
        redirect url_for(:date, date) unless fort_types?(fort)
        @targets = fort_nums.map{|i| "#{fort}#{i}"}
        @timeline = FortTimeline.build_for(date)
        redirect url_for(:date, date) unless @timeline
        render :fort_timeline
      end
    end

    get :fort_timeline_each, :map => '/d/:date/f/:fort/:num' do
      date_action do |date|
        fid = "#{params[:fort]}#{params[:num]}"
        redirect url_for(:date, date) unless exist_fort?(fid)
        @targets = [fid]
        @timeline = FortTimeline.build_for(date)
        redirect url_for(:date, date) unless @timeline
        render :fort_timeline
      end
    end

    get '/d/:date/g/?' do
      date_action do |date|
        redirect url_for(:union_select, date)
      end
    end

    get :guild_timeline, :map => '/d/:date/g/:name' do
      date_action do |date|
        @timeline = GuildTimeline.build_for(date, decode_for_url(params[:name]))
        redirect url_for(:date, date) unless @timeline
        render :guild_timeline
      end
    end

    get :union_select, :map => '/d/:date/u/?' do
      date_action do |date|
        @names = guild_names_for_date(date)
        render :union
      end
    end

    post :union_select, :map => '/d/:date/u/?' do
      date_action do |date|
        names = guild_names_for_date(date)
        gs = [params[:guild]].flatten.uniq.compact.reject(&:empty?).select{|n| names.include?(n)}
        redirect url_for(:union_select, date) if gs.empty?
        redirect url_for(:guild_timeline, date, encode_for_url(gs.first)) if gs.size == 1
        redirect url_for(:union_timeline, date, gs.map{|n| encode_base64_for_url(n)}.flatten.join(','))
      end
    end

    get :union_timeline, :map => '/d/:date/u/:names' do
      date_action do |date|
        names = guild_names_for_date(date)
        gs = params[:names].split(/,/).uniq.compact.reject(&:empty?).map{|s| decode_base64_for_url(s)}.select{|g| names.include?(g)}
        redirect url_for(:union_select, date) if gs.empty?
        redirect url_for(:guild_timeline, date, encode_for_url(gs.first)) if gs.size == 1
        @timeline = GuildTimeline.build_for(date, gs)
        redirect url_for(:date, date) unless @timeline
        render :guild_timeline
      end
    end

    get :rev_each, :map => '/r/:rev' do
      @situation = Situation.find_by_revision(params[:rev])
      redirect url_for(:index) unless @situation
      render :rev
    end

    delete :delete, :map => '/r/:rev' do
      rev_path = url_for(:rev_each, params[:rev])
      redirect rev_path unless updatable_mode?
      redirect rev_path unless valid_delete_key?(params[:dkey])
      s = Situation.find_by_revision(params[:rev])
      s.leave! if s
      redirect url_for(:index)
    end

    put '/update' do
      protect_action do
        data = JSON.parse(params['d'])
        Updater.update_form(data)
        'OK'
      end
    end

    post '/status' do
      protect_action do
        'OK'
      end
    end

    get '/latest' do
      (halt 404) if sample_mode?
      @situation = Situation.latest || Situation.new
      @situation.to_json
    end

    post '/latest' do
      protect_action do
        @situation = Situation.latest || Situation.new
        @situation.to_json
      end
    end

    put '/cutin' do
      protect_action do
        data = JSON.parse(params['d'])
        Situation.cut_in_from(data)
        'OK'
      end
    end

  end
end
