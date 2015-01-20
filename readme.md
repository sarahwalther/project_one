# Progress Notes

> It can be very tricky for special ed teachers to keep track of the daily progress students are making with the limited time there is available. Here is a quick way of adding a line or two about the way the day went for teachers.

![Picture of School](http://www.clipartbest.com/cliparts/MKT/jo7/MKTjo7Liq.png =700x)


## User Stories

#### Project Sprint

As a teacher (user)...

1. I can log in with LinkedIn.
1. I can log out.
1. when I log in, the application will use my LinkedIn profile to set my job title.
1. I can see a list of student-rooms I have access to.
1. I can create student rooms (including setting his/her goals).
1. I can see a list of other teachers.
1. I can give access to a room for a teacher.
1. when I am in a student-room, I can see the student's goals.
1. when I am in a student-room, I see a list of messages about the student.
1. I can create time stamped student progress entries (messages).
1. I can delete my own messages.
1. I can edit, add. or remove a goal after I created a student
1. I can rate a student's behavior
1. I can search the messages by user and date.

#### Icebox

1. I can see uploaded visual aids and other graphic information. (make this more explicit)
1. I can comment on other teachers' messages.
1. I can filter by tags that may have been added to the comments (ex: behavior).
1. Issues to work out if there's time:
1. student input to First Last name to save it as first_last
1. add teachers by email address, not last name

## API and Gems used

* LinkedIn API - to log in to the app through an outside provider
* Redis Gem - to use the Redis database to store information
* Sinatra Gem - a web framework to build the skelleton of the app
* HTTParty Gem - to access the LinkedIn API
* JSON Gem - to translate from and to Ruby

## Instructions to run this App locally

Clone the Repo and cd into it

	$ git clone git@github.com:sarahmcalear/project_one.git
	$ cd project_one

Now install the required Gems and boot up your Redis server and start you app in separate Terminal windows

	$ bundle install
	$ redis-server
	$ rackup





