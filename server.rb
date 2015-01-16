require_relative 'database_helper'

module ProgressNotes
  class Server < Sinatra::Base
    helpers ProgressNotes::DatabaseHelper

    enable :logging, :sessions, :method_override

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

    get('/students/:id/edit') do
      binding.pry
    end

    get('/students/new?:name?:note_id?:goals?') do
      if params[:name] != nil
        @id = check_student(params[:name])
        if params[:goals] != nil
          @goals = "goals"
        elsif params[:note_id] != nil
          @note_id = params[:note_id]
        end
      end
      render(:erb, :new, {:layout => :default})
    end

    get('/students/:id') do
      @id = params[:id]
      @student = $redis.hgetall("student:#{@id}")
      render(:erb, :show, {:layout => :default})
    end

    post('/?:name?:id?') do
      name = params[:name]
      if params[:id] != nil
        id = params[:id]
        $redis.hset(
          "student:#{id}",
          "goals", (params["goals"]).to_json
          )

      elsif check_student(name) != nil
        id = check_student(name).to_i
        $redis.hmset(
          "student:#{id}",
          "grade", params["grade"],
          "parent", params["parent"],
          "contact", params["contact"]
          )

      else
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
      end
      redirect('/')
    end

    post('/students/?:id?:note_id?') do
      @id           = params[:id]
      teacher       = params["addteacher"]
      add_teacher(teacher)
      if params[:note_id] != nil
        @note_id = params[:note_id]
        check_note(@id, @note_id)

      elsif params["progress_note"] != nil
        id = $redis.incr("note_ids")
        date          = Date.today
        progress_note = params["progress_note"]
        behavior      = params["rating"]
        teacher       = session[:l_name]
        picture       = session[:user_image]
        add_note(id, date, progress_note, teacher, behavior)
      end
      redirect("/students/#{@id}")
    end

    delete('students/notes/:id/:note_id') do
      biding.pry
    end

    delete('/students/:id') do
      binding.pry
      id = params[:id]
      $redis.del("student:#{id}")
      redirect to('/')
    end

  end
end





















