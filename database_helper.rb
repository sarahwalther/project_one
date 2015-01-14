module ProgressNotes
  module DatabaseHelper

    $redis = Redis.new

    def get_user_info
      response = HTTParty.get("https://api.linkedin.com/v1/people/~:(first-name,last-name,email-address,picture-url,headline)?format=json",
        :headers => {
          "Authorization" => "Bearer #{session[:access_token]}",
          "User-Agent"    => "Progress notes"
          }
          )
      session[:email]       = response["emailAddress"]
      session[:f_name]      = response["firstName"]
      session[:l_name]      = response["lastName"]
      session[:user_image]  = response["pictureUrl"]
      session[:job_title]   = response["headline"]
      session[:provider]    = "LinkedIn"
      if $redis.hexists("teachers", session[:email])
      else
        $redis.hset("teachers", session[:email], session[:l_name])
      end
    end

    def add_teacher(teacher)
      teachers = []
      teachers << (@student["teacher_admin"])
      teachers << $redis.hget("teachers", teacher)
      $redis.hset(
        "student:#{@student["sid"]}",
        "teachers", teachers.to_json)
    end

  end
end
