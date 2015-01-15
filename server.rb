require_relative 'database_helper'

module ProgressNotes
  class Server < Sinatra::Base
    helpers ProgressNotes::DatabaseHelper

    enable :logging, :sessions

    configure :development do
      register Sinatra::Reloader
      require 'pry'
    end

    $redis = Redis.new

    get('/') do
      query_params = URI.encode_www_form({
        :client_id      => ENV["LINKEDIN_OAUTH_ID"],
        :scope          => "r_basicprofile r_emailaddress",
        :response_type  => "code",
        :state          => "YGCFTRDfd3245ghjfhd",
        :redirect_uri   => "http://localhost:9292/linkedin/oauth_callback"
        })
      @linkedin_auth_url = "https://www.linkedin.com/uas/oauth2/authorization?" + query_params
      binding.pry
      render(:erb, :index, {:layout => :default})
    end

    get("/linkedin/oauth_callback") do
      response = HTTParty.post("https://www.linkedin.com/uas/oauth2/accessToken",
        :body   => {
          :code           => params[:code],
          :client_id      => ENV["LINKEDIN_OAUTH_ID"],
          :client_secret  => ENV["LINKEDIN_OAUTH_SECRET"],
          :redirect_uri   => "http://localhost:9292/linkedin/oauth_callback",
          :grant_type     => "authorization_code"
          },
          :headers  => {
            "Accept"  => "application/json"
            }
      )
      # here you get back an access token that will be used for your session.
      session[:access_token] = response["access_token"]
      get_user_info
      redirect to('/')
    end

    get('/logout') do
      session[:f_name] = session[:access_token] = nil
      redirect to('/')
    end

    get('/students/new') do
      render(:erb, :new, {:layout => :default})
    end

    get('/students/:id') do
      @id = params[:id]
      @student = $redis.hgetall("student:#{@id}")
      binding.pry
      render(:erb, :show, {:layout => :default})
    end

    post('/') do
      sid = $redis.incr("student_id")
      date = Date.today
      $redis.hmset(
        "student:#{sid}",
        "name", params["name"],
        "grade", params["grade"],
        "parent", params["parent"],
        "contact", params["contact"],
        "goals", (params["goals"]).to_json, # this is now a string and needs to be called with JSON.parse(goals)
        "teacher_admin", session[:l_name],
        "sid", "#{sid}",
        "date", Date.parse("#{date}").strftime("%b %d, %Y")
        )
      $redis.lpush("student_ids", sid)
      redirect('/')
    end

    post('/students/:id') do
      @id = params[:id]
      teacher = params["addteacher"]
      binding.pry
      add_teacher(teacher)
      redirect("/students/#{@id}")
    end

  end
end





















