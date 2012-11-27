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

  end
end
