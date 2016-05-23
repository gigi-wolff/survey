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

def user_error_message
  message = ""
  message += "first name," if params[:first_name] == ""
  message += " last name" if params[:last_name] == ""

  message == "" ? nil : message.chomp(',')
end

def error_message
  message = ""
  message = "difficulty level between 1 through 5(hardest)," unless (1..5).cover?(params[:difficulty].to_i)
  message += " comment" if params[:comment] == ""

  message == "" ? nil : message.chomp(',')
end

def valid_user?
  # _FILE_ a reference to the current file name
  # File.expand_path('../users.yml', __FILE__) is a trick to get
  # the absolute path of a file when you know the path relative to the current file
  # File.expand_path = "/Users/Gigi/survey/users.yml"
  credentials = YAML.load_file( File.expand_path("../users.yml", __FILE__) ) #users.yml (hash) username: password

  if credentials.key?(params[:username])
    bcrypt_password = BCrypt::Password.create(credentials[params[:username]]) # encrypt password in .yml file
    bcrypt_password == params[:password] # compare it to password entered by user
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
  #if valid_user?(params[:username], params[:password])
    if valid_user?
    session[:success] = "Signed In"
    redirect "/user_info"
  else
    session[:error] = "Invalid Username Password combination"
    status 422
    erb :signin
  end
end

# create new survey entry -------
get "/user_info" do
  erb :user_info  
end

post "/user_info" do
  error = user_error_message

  if error
    session[:error] = "Please enter: #{error}"
    status 422
    # Values of input fields should be set to params if they need to be
    # validated. Now the user won't have to re-enter them if 
    # the page is re-rendered because of an invalid input
    erb :user_info
  else
    session[:first_name] = params[:first_name]
    session[:last_name] = params[:last_name]
    # None of the variables created in this action
    # will be available to the redirected view unless they are saved in session
    redirect "/survey/#{session[:last_name]}" #survey successfully created goto comment action
  end
end

# create new review -----------
get "/survey/:last_name" do
  erb :create
end

post "/survey/:last_name" do
  error = error_message

  if error
    session[:error] = "Please enter: #{error}"
    status 422
    erb :create    
  else
    session[:comment] = params[:comment]
    session[:difficulty] = params[:difficulty]
    redirect "/survey/show/#{session[:last_name]}"
  end
end

# show review (choose edit or save) -------------
get "/survey/show/:last_name" do
  erb :show
end

# update review -------------------
get "/survey/edit/:last_name" do
  erb :update
end

post "/survey/edit/:last_name" do
  error = error_message

  if error
    session[:error] = "Please enter: #{error}"
    status 422
    erb :update    
  else
    session[:comment] = params[:comment]
    session[:difficulty] = params[:difficulty]
    session[:success] = "The review has been updated."
    redirect "/survey/show/#{session[:last_name]}"
  end
end

# save final review ------------
post "/survey/save/:last_name" do
  session[:success] = "Your review has been saved."
  erb :saved
end

# delete review --------------
post "/survey/delete/:last_name" do
  session[:comment] = nil
  session[:difficulty] = nil
  session[:success] = "The review has been deleted."
  redirect "/survey/show/:last_name"
end 









