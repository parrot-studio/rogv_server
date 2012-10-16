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
        '全て'
      when :total
        TotalResult.cache_clear!
        '結果データ'
      end

      flash[:info] = "#{str}のキャッシュをクリアしました" if str
      redirect url_for(:a, :cache)
    end

  end
end
