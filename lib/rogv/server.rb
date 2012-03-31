# coding: utf-8
require 'date'
require 'base64'
require 'uri'
require 'json'
require 'sinatra/base'

module ROGv
  class Server < Sinatra::Base
    set :root, WEB_ROOT

    use Rack::MethodOverride
    unless ServerConfig.auth_sample_mode
      use Rack::Auth::Basic do |user, pass|
        user == ServerConfig.auth_username && pass == ServerConfig.auth_password
      end
    end

    helpers do
      include Rack::Utils
      alias_method :h, :escape_html

      def app_path
        ServerConfig.app_path
      end

      def url_for(path, val = nil)
        return unless path
        vs = [val].flatten.compact

        ret = case path
        when :root
          "#{app_path}/"
        when :reload
          "#{app_path}/?re=#{val}"
        when :date_list
          "#{app_path}/d"
        when :date
          "#{app_path}/d/#{val}"
        when :rev_list
          "#{app_path}/d/#{val}/r"
        when :rev
          case vs.size
          when 1
            "#{app_path}/r/#{val}"
          when 2
            "#{app_path}/d/#{vs.first}/r/#{vs.last}"
          end
        when :fort_timeline
          case vs.size
          when 2..3
            d = vs.shift
            "#{app_path}/d/#{d}/f/#{vs.join('/')}"
          end
        when :guild_timeline
          case vs.size
          when 2
            "#{app_path}/d/#{vs.first}/g/#{vs.last}"
          end
        when :delete
          "#{app_path}/r/#{val}"
        when :union_select
          "#{app_path}/d/#{val}/u"
        when :union
          d = vs.shift
          "#{app_path}/d/#{d}/u/#{vs.join(',')}"
        end

        ret ? ret : "#{app_path}/"
      end

      def to_jst_datetime(t)
        return unless t
        (t.utc? ? t + Time.now.utc_offset : t).to_datetime
      end

      def format_time(t)
        return unless t
        d = to_jst_datetime(t)
        format("%04d/%02d/%02d %02d:%02d:%02d",
          d.year, d.month, d.day, d.hour, d.min, d.sec)
      end

      def format_time_only(t)
        return unless t
        d = to_jst_datetime(t)
        format("%02d:%02d:%02d", d.hour, d.min, d.sec)
      end

      def devided_date(ds)
        return unless ds
        "#{ds[0..3]}/#{ds[4..5]}/#{ds[6..7]}"
      end

      def time_to_revision(t)
        return unless t
        d = to_jst_datetime(t)
        format("%04d%02d%02d%02d%02d%02d",
          d.year, d.month, d.day, d.hour, d.min, d.sec)
      end

      def partial_render(name)
        return unless name
        erb("_#{name}".to_sym, :layout => false)
      end

      def reload_cycle
        ['30', '60', '120']
      end

      def sample_mode?
        ServerConfig.auth_sample_mode ? true : false
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
    end

    get '/' do
      if params[:re]
        @reload = params[:re]
        redirect url_for(:root) unless reload_cycle.include?(@reload)
      end
      @unlink = true
      @situation = Situation.latest || Situation.new
      erb :index
    end

    get '/d/?' do
      @dlist = Situation.date_list
      erb :date_list
    end

    get '/d/:date' do
      date_action do |date|
        @dlist = [date]
        erb :date_list
      end
    end

    get '/d/:date/r/?' do
      date_action do |date|
        @revs = Situation.for_date(date).sort(:revision.desc)
        redirect url_for(:date, date) if @revs.none?
        erb :rev_list
      end
    end

    get '/d/:date/r/:rev' do
      date_action do |date|
        @situation = Situation.find_by_revision(params[:rev])
        redirect url_for(:date, date) unless @situation
        erb :rev
      end
    end

    get '/d/:date/f/?' do
      date_action do |date|
        redirect url_for(:date, date)
      end
    end

    get '/d/:date/f/SE' do
      date_action do |date|
        @targets = []
        ['N', 'F'].each do |t|
          fort_nums.each{|i| @targets << "#{t}#{i}"}
        end
        @timeline = FortTimeline.build_for(date)
        redirect url_for(:date, date) unless @timeline
        erb :fort_timeline
      end
    end

    get '/d/:date/f/:fort' do
      date_action do |date|
        fort = params[:fort]
        redirect url_for(:date, date) unless fort_types?(fort)
        @targets = fort_nums.map{|i| "#{fort}#{i}"}
        @timeline = FortTimeline.build_for(date)
        redirect url_for(:date, date) unless @timeline
        erb :fort_timeline
      end
    end

    get '/d/:date/f/:fort/:num' do
      date_action do |date|
        fid = "#{params[:fort]}#{params[:num]}"
        redirect url_for(:date, date) unless exist_fort?(fid)
        @targets = [fid]
        @timeline = FortTimeline.build_for(date)
        redirect url_for(:date, date) unless @timeline
        erb :fort_timeline
      end
    end

    get '/d/:date/g/?' do
      date_action do |date|
        redirect url_for(:date, date)
      end
    end

    get '/d/:date/g/:name' do
      date_action do |date|
        @timeline = GuildTimeline.build_for(date, params[:name])
        redirect url_for(:date, date) unless @timeline
        erb :guild_timeline
      end
    end

    get '/d/:date/u/?' do
      date_action do |date|
        @names = Situation.guild_names_for(date)
        erb :union
      end
    end

    post '/d/:date/u/?' do
      date_action do |date|
        names = Situation.guild_names_for(date)
        gs = [params[:guild]].flatten.uniq.compact.reject(&:empty?).select{|n| names.include?(n)}
        redirect url_for(:union_select, date) if gs.empty?
        redirect url_for(:guild_timeline, [date, encode_for_url(gs.first)]) if gs.size == 1
        redirect url_for(:union, [date, gs.map{|n| encode_base64_for_url(n)}].flatten)
      end
    end

    get '/d/:date/u/:names' do
      date_action do |date|
        names = Situation.guild_names_for(date)
        gs = params[:names].split(/,/).uniq.compact.reject(&:empty?).map{|s| decode_base64_for_url(s)}.select{|g| names.include?(g)}
        redirect url_for(:union_select, date) if gs.empty?
        redirect url_for(:guild_timeline, [date, encode_for_url(gs.first)]) if gs.size == 1
        @timeline = GuildTimeline.build_for(date, gs)
        redirect url_for(:date, date) unless @timeline
        erb :guild_timeline
      end
    end

    put '/update' do
      protect_action do
        data = JSON.parse(params['d'])
        Situation.update_from(data)
      end
    end

    post '/status' do
      protect_action
    end

    get '/r/:rev' do
      @situation = Situation.find_by_revision(params[:rev])
      redirect url_for(:root) unless @situation
      erb :rev
    end

    delete '/r/:rev' do
      rev_path = url_for(:rev, params[:rev])
      redirect rev_path if sample_mode?
      redirect rev_path unless valid_delete_key?(params[:dkey])
      s = Situation.find_by_revision(params[:rev])
      s.leave! if s
      redirect url_for(:root)
    end

    not_found do
      erb :not_found
    end

    error do
      erb :error
    end

    private

    def date_action
      @date = params[:date]
      redirect url_for(:date_list) unless @date
      redirect url_for(:date_list) unless Situation.date_list.include?(@date)
      yield(@date)
    end

    def protect_action
      (halt 403) if sample_mode?
      (halt 403) unless params['k'] == ServerConfig.auth_key
      yield if block_given?
      'OK'
    end

    def valid_delete_key?(dkey)
      return false unless dkey
      return false if dkey.empty?
      dkey == ServerConfig.auth_delete_key ? true : false
    end

    def encode_base64_for_url(s)
      Base64.urlsafe_encode64(s)
    end

    def decode_base64_for_url(s)
      Base64.urlsafe_decode64(s).force_encoding('UTF-8')
    end
  end
end
