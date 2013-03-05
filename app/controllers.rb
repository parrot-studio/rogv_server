# coding: utf-8
module ROGv
  ROGv::Server.controllers  do

    get :index do
      if params[:re]
        @reload = params[:re]
        redirect url_for(:index) unless reload_cycle.include?(@reload)
      end
      @unlink = true
      @nonav = true
      @situation = Situation.latest || Situation.new
      render :index
    end

    get :menu, :map => '/sr/?' do
      render :menu
    end

    put :update do
      protect_action do
        data = JSON.parse(params['d'])
        Updater.update_form(data)
        'OK'
      end
    end

    post :status do
      protect_action do
        'OK'
      end
    end

    get :latest do
      (halt 404) if sample_mode?
      @situation = Situation.latest || Situation.new
      @situation.to_json
    end

    post :latest_post, :map => '/latest' do
      protect_action do
        @situation = Situation.latest || Situation.new
        @situation.to_json
      end
    end

    put :cutin do
      protect_action do
        data = JSON.parse(params['d'])
        Situation.cut_in_from(data)
        'OK'
      end
    end

  end
end
