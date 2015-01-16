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
        $redis.hset("teacher_thumbnails", session[:l_name], session[:user_image])
      end
    end

    def add_teacher(teacher)
      teachers = []
      teachers << $redis.hget("teachers", teacher)
      $redis.hset(
        "student:#{@id}",
        "teachers", teachers.to_json)
    end

    def add_note(note_id, date, progress_note, teacher, behavior)
      note = [note_id, date.to_s, progress_note, teacher, behavior].to_json
      if $redis.hget("student:#{@id}",
        "notes") != nil
        notes = JSON.parse($redis.hget("student:#{@id}",
        "notes"))
      else
        notes = []
      end
      notes << note
      $redis.hset(
        "student:#{@id}",
        "notes", notes.to_json)
    end

    # this method returns the id of the student, if a student already exists
    def check_student(student)
      list = $redis.lrange("student_ids", 0, -1).select do |id|
        if $redis.hget("student:#{id}", "name") == student
          id
        end
      end
      list[0]
    end

    def check_note(id, note_id)
      student_notes_as_string = $redis.hget("student:#{id}", "notes")
      student_notes = JSON.parse(student_notes_as_string)
      desired_note = student_notes.select do |note|
        # binding.pry
        JSON.parse(note)[0] == note_id.to_i
      end
      desired_note[0]
    end


  end
end
