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

    get('/edit_students/:id') do
      @id = params[:id]
      render(:erb, :edit, {:layout => :default})
    end

    post('/edit_students/:id') do
      id        = params[:id]
      $redis.hmset(
          "student:#{id}",
          "grade", params["grade"],
          "parent", params["parent"],
          "contact", params["contact"]
          )
      redirect to("/students/#{id}")
    end

    get('/goals/student/:id') do
      @id = params[:id]
      render(:erb, :edit_goals, {:layout => :default})
    end

    post('/goals/student/:id') do
      id       = params[:id]
      $redis.hset(
          "student:#{id}",
          "goals", (params[:goals]).to_json
          )
      redirect to("/students/#{id}")
    end

    get('/note/student/:id&:note_id') do
      @id         = params[:id]
      @note_id   = params[:note_id]
      @note = check_note(@id, @note_id)
      render(:erb, :edit_note, {:layout => :default})
    end

    post('/note/student/:id&:note_id') do
      id            = params[:id]
      note_id       = params[:note_id]
      new_note      = params[:progress_note]
      new_rating    = params[:rating]
      date          = Date.today
      author        = session[:l_name]
      replace_note(id, note_id, date, new_note, author, new_rating)
      redirect to("/students/#{id}")
    end

    get('/students/new') do
      render(:erb, :new, {:layout => :default})
    end

    get('/students/:id') do
      @id = params[:id]
      @student = $redis.hgetall("student:#{@id}")
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

    post('/students/?:id?:note_id?') do
      @id           = params[:id]
      teacher       = params[:addteacher]
      add_teacher(teacher)
      if params[:note_id] != nil
        @note_id = params[:note_id]
        check_note(@id, @note_id)

      elsif params["progress_note"] != nil
        id = $redis.incr("note_ids")
        date          = Date.today
        progress_note = params[:progress_note]
        behavior      = params[:rating]
        teacher       = session[:l_name]
        picture       = session[:user_image]
        add_note(id, date, progress_note, teacher, behavior)
      end
      redirect("/students/#{@id}")
    end

    delete('/students/notes/:id/:note_id') do
      id = params[:id]
      note_id = params[:note_id]
      note = check_note(id, note_id)
      note_array = find_notes_array(id, note_id)
      note_array.delete(note)
      $redis.hset(
        "student:#{id}",
        "notes", note_array.to_json)
      redirect to("/students/#{id}")
    end

    delete('/students/:id') do
      id = params[:id]
      $redis.del("student:#{id}")
      redirect to('/')
    end

  end
end





















