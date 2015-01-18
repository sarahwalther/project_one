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
        JSON.parse(note)[0].to_i == note_id.to_i
      end
      desired_note[0]
    end

    def find_notes_array(id, note)
      student_notes_as_string = $redis.hget("student:#{id}", "notes")
      student_notes = JSON.parse(student_notes_as_string)
      student_notes
    end

    def find_index(desired_note, student_notes)
      index = student_notes.index(desired_note)
    end

    def replace_note(id, note_id, date, new_note, author, new_rating)
      desired_note = check_note(id, note_id)
      student_notes = find_notes_array(id, desired_note)
      index = find_index(desired_note, student_notes)
      date          = date.to_s
      note_array    = JSON.parse(desired_note)
      note_array[1].replace(date)
      if new_note  != nil
       note_array[2].replace(new_note)
     end
      note_array[3].replace(author)
      if new_rating != nil
        note_array[4].replace(new_rating)
      end
      student_notes[index].replace(note_array.to_json)
      $redis.hset(
        "student:#{id}",
        "notes", student_notes.to_json)
    end

  end
end
