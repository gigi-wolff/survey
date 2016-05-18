require "pry"
require "redcarpet"
require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"
require "yaml"
require "bcrypt"


configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

def error_message
  message = ""
  message += "first name," if params[:first_name] == ""
  message += " last name," if params[:last_name] == ""
  message += " 

  difficulty range 1 through 5" unless ("1".."5").cover?(params[:difficulty])
  message == "" ? nil : message.chomp(',')
end

def valid_user?(username, password)
  # _FILE_ a reference to the current file name
  # File.expand_path('../users.yml', __FILE__) is a trick to get
  # the absolute path of a file when you know the path relative to the current file
  # File.expand_path = "/Users/Gigi/survey/users.yml"
  # credentials  = {"developer"=>"letmein,", "gigi"=>"whatnow"}
  credentials = YAML.load_file( File.expand_path("../users.yml", __FILE__) ) #users.yml (hash) username: password

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.create(credentials[username]) # encrypt password in .yml file
    bcrypt_password == password # compare it to password entered by user
  else
    false
  end
end

get "/" do
  redirect "/user/signin"
end

get "/user/signin" do
  erb :signin  
end

post "/user/signin" do
  if valid_user?(params[:username], params[:password])
    session[:message] = "Signed In"
    redirect "/survey"
  else
    session[:message] = "Invalid Username Password combination"
    status 422
    erb :signin
  end
end

# create new survey entry -------
get "/survey" do
  erb :survey  
end

post "/survey" do
  error = error_message
  if error
    session[:message] = "Please enter: #{error}"
    status 422
    # Values of input fields should be set to params so we don't have to revalidate each them.
    # If it is the first render, params[:first_name] is nil, so the field will be empty. 
    # If it is a re-render, the field will be filled in if they filled it in and empty if they didn't. 
    # This helps us to avoid having to write conditionals as it all comes for free by using params in that situation.
    erb :survey 
  else
    session[:first_name] = params[:first_name]
    session[:last_name] = params[:last_name]
    session[:difficulty] = params[:difficulty]
    # None of the variables created in this action
    # will be available to the redirected view unless they are saved in session
    redirect "/comment/#{session[:last_name]}" #survey successfully created goto comment action
  end
end

# create new comment -----------
get "/comment/:lastname" do
  erb :comment
end

post "/comment/:lastname" do
  if params[:comment]==""
    session[:message] = "Please enter a comment"
    status 422
    erb :comment
  else
    session[:comment] = params[:comment]
    redirect "/edit"
  end
end

# update survey -------------
get "/edit" do
  @lastname = session[:last_name]
  erb :edit
end

get "/difficulty/edit" do
  erb :difficulty
end

post "/difficulty/edit" do
  if (1..5).include?(params[:difficulty].to_i)
    session[:message] = "Difficulty level updated."
    session[:difficulty] = params[:difficulty]
    redirect "/edit"
  else
    session[:message] = "Please enter a difficulty level 1 to 5(hardest)"
    status 422
    erb :edit
  end
end

post "/comment/edit" do
  redirect "/comment/#{session[:last_name]}"
end

# show result ------------
post "/receipt" do
  erb :receipt
end






