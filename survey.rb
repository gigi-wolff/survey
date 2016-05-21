require "pry"
require "redcarpet"
require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"
require "yaml"
require "bcrypt"

# <input type="text"  maxlength="100" size="100" name="comment" value="<%= params[:comment] || session[:comment] %>" >


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

def review_error_message
  message = ""
  message = "difficulty level between 1 through 5(hardest)," unless (1..5).cover?(params[:difficulty].to_i)
  message += " comment" if params[:comment] == ""

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
    # Values of input fields should be set to params so we don't have to revalidate each them.
    # If it is the first render, params[:first_name] is nil, so the field will be empty. 
    # If it is a re-render, the field will be filled in if they filled it in and empty if they didn't. 
    # This helps us to avoid having to write conditionals as it all comes for free by using params in that situation.
    erb :user_info
  else
    session[:first_name] = params[:first_name]
    session[:last_name] = params[:last_name]
    # None of the variables created in this action
    # will be available to the redirected view unless they are saved in session
    redirect "/survey/create_review/#{session[:last_name]}" #survey successfully created goto comment action
  end
end

# create new review -----------
get "/survey/create_review/:last_name" do
  erb :create_review
end

post "/survey/create_review/:last_name" do
  error = review_error_message

  if error
    session[:error] = "Please enter: #{error}"
    status 422
    erb :create_review    
  else
    session[:comment] = params[:comment]
    session[:difficulty] = params[:difficulty]
    redirect "/survey/show_review/#{session[:last_name]}"
  end
end

# show review (choose edit or save) -------------
get "/survey/show_review/:last_name" do
  erb :show_review
end

# update review -------------------
get "/survey/update_review/:last_name" do
  erb :update_review
end

post "/survey/update_review/:last_name" do
  error = review_error_message

  if error
    session[:error] = "Please enter: #{error}"
    status 422
    erb :update_review    
  else
    session[:comment] = params[:comment]
    session[:difficulty] = params[:difficulty]
    session[:success] = "The review has been updated."
    redirect "/survey/show_review/#{session[:last_name]}"
  end
end

# save final review ------------
get "/survey/save_review/:last_name" do
  session[:success] = "Your review has been saved."
  erb :saved_review
end

