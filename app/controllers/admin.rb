# coding: utf-8
module ROGv
  ROGv::Server.controllers :a do

    before :except => :login do
      redirect url_for(:index) unless updatable_mode?
      unless logined?
        flash[:error] = 'ログインが確認できませんでした'
        redirect url_for(:a, :login)
      end
    end

    get :index do
      render 'admin/index'
    end

    get :login do
      clear_session
      redirect url_for(:index) unless updatable_mode?
      render 'admin/login'
    end

    post :login do
      unless valid_admin?(params[:user], params[:pass])
        flash[:error] = 'ユーザ名かパスワードが誤っています'
        redirect url_for(:a, :login)
      end
      login_for(params[:user])
      redirect url_for(:a, :index)
    end

    delete :logout do
      clear_session
      redirect url_for(:a, :login)
    end

    get :backup do
      @files = DumpFile.all
      render 'admin/backup'
    end

    post :backup do
      begin
        Dumper.execute
      rescue
        flash[:error] = 'バックアップに失敗しました'
      end
      redirect url_for(:a, :backup)
    end

    get :backup_download, :map => '/a/backup/:rev' do
      df = DumpFile.find_by_revision(params[:rev])
      redirect url_for(:a, :backup) unless df
      send_file df.full_path,
        :type => 'application/x-gzip',
        :filename => df.filename
    end

    delete :backup_delete, :map => '/a/backup/:rev' do
      df = DumpFile.find_by_revision(params[:rev])
      df.delete! if df
      redirect url_for(:a, :backup)
    end

    get :cache do
      render 'admin/cache'
    end

    delete :cache_delete, :with => :target do
      str = case params[:target].to_sym
      when :all
        TotalResult.cache_clear!
        FortTimeline.cache_clear!
        GuildTimeline.cache_clear!
        '全て'
      when :total
        TotalResult.cache_clear!
        '結果データ'
      when :fort_timeline
        FortTimeline.cache_clear!
        '砦タイムラインデータ'
      when :guild_timeline
        GuildTimeline.cache_clear!
        'ギルドタイムラインデータ'
      end

      flash[:info] = "#{str}のキャッシュをクリアしました" if str
      redirect url_for(:a, :cache)
    end

    get :result do
      render 'admin/result'
    end

    post :result_add_total, :map => '/a/result' do
      date = params[:add_total_date]
      dates = if date
        Situation.date_list.include?(date) ? [date] : []
      else
        last_date = TotalResult.all_total.gv_dates.max
        Situation.date_list.select{|d| d > last_date}
      end

      dates.each do |d|
        Situation.repair_duplication!(d)
        wr = WeeklyResult.for_date(d)
        wr ||= WeeklyResult.analyze_for(d)
        next unless wr
        wr.save! if wr.new_record?
        TotalResult.add_result_to_all_total!(d)
        FortResult.add_result(d)
      end

      flash[:info] = 'データ集計が完了しました'
      redirect url_for(:a, :result)
    end

    get :manual_input, :map => '/a/manual_input' do
      @results = if params[:all]
        WeeklyResult.sort(:gv_date.desc)
      else
        WeeklyResult.manuals
      end
      render 'admin/manual_input'
    end

    post :manual_input_new, :map => '/a/manual_input' do
      begin
        date = format('%04d%02d%02d', params[:year].to_i, params[:month].to_i, params[:day].to_i)
        Date.parse(date)
        redirect url_for(:a, :manual_input_view, date)
      rescue ArgumentError
        flash[:error] = '日付指定が異常です'
        redirect url_for(:a, :manual_input)
      end
    end

    get :manual_input_view, :map => '/a/manual_input/:date' do
      date = params[:date]
      unless valid_gvdate?(date)
        flash[:error] = '日付指定が異常です'
        redirect url_for(:a, :manual_input)
      end

      @result = WeeklyResult.for_date(date) || lambda do
        wr = WeeklyResult.new
        wr.gv_date = date
        wr.source = 'manual'
        wr
      end.call
      render 'admin/manual_input_view'
    end

    post :manual_input_add_total, :map => '/a/manual_input/:date' do
      date = params[:date]
      unless valid_gvdate?(date)
        flash[:error] = '日付指定が異常です'
        redirect url_for(:a, :manual_input)
      end

      wr = WeeklyResult.for_date(date)
      unless wr
        flash[:error] = '指定された日付のデータは存在しません'
        redirect url_for(:a, :manual_input)
      end

      TotalResult.add_result_to_all_total!(wr.gv_date)
      FortResult.add_manual_result(wr)

      flash[:info] = "#{devided_date(wr.gv_date)}の結果を反映しました"
      redirect url_for(:a, :manual_input)
    end

    put :manual_input_update, :map => '/a/manual_input/:date' do
      date = params[:date]
      unless valid_gvdate?(date)
        flash[:error] = '日付指定が異常です'
        redirect url_for(:a, :manual_input)
      end

      @result = WeeklyResult.for_date(date) || lambda do
        wr = WeeklyResult.new
        wr.gv_date = date
        wr.source = 'manual'
        wr
      end.call
      if @result.analyzed?
        flash[:error] = '自動集計済みの結果なので、手動更新できません'
        redirect url_for(:a, :manual_input_view, date)
      end

      @result.parse_manual_inputs(params[:gname])
      if @result.save
        flash[:info] = "#{devided_date(date)}の結果を更新しました"
        redirect url_for(:a, :manual_input_view, date)
      else
        render 'admin/manual_input_view'
      end
    end

    delete :manual_input_delete, :map => '/a/manual_input/:date' do
      date = params[:date]
      result = WeeklyResult.for_date(date)
      redirect url_for(:a, :manual_input) unless (result && result.manual?)

      result.destroy
      flash[:info] = "#{devided_date(date)}の結果を削除しました"
      redirect url_for(:a, :manual_input)
    end

  end
end
