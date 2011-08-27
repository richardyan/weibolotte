%w(rubygems bundler).each { |dependency| require dependency }
Bundler.setup
%w(sinatra haml oauth sass json weibo).each { |dependency| require dependency }
enable :sessions
Weibo::Config.api_key = "287181093"
Weibo::Config.api_secret = "9077339bcdfd2ae006a6ab0da4590131"
SERVER       = %{http://api.t.sina.com.cn}
FOLLOW       = %{/friendships/create/}
USERTWEET    = %{/statuses/user_timeline/}
FLOWING      = "1801580672"
#FLOWING = "2126110313"
YAYAID = "2341418874" 
ACCESS = "287181093"
SECRET = "9077339bcdfd2ae006a6ab0da4590131"
PATH = "#{SERVER}#{USERTWEET}#{FLOWING}.json?source=#{ACCESS}"
APP_DIR = File.dirname(__FILE__)
startid = File.read("#{APP_DIR}/../tweetid").strip

require "#{APP_DIR}/../helper/oauth_helper"
include OauthHelper

text = {
         :status => URI.encode('good ~ @minyooyoo @ainiyqi @richardmaz @maztz @uouyn')
         }
#class WeiboLotte < Sinatra::Base
  get '/' do
    if session[:atoken]
      redirect "/user_profile"
    else
      redirect "/login"
    end

  end
  
  get "/friends_timeline" do
    @timeline = Weibo::Base.new(authorize(Weibo::Config.api_key, Weibo::Config.api_secret)).friends_timeline
    haml :friends_timeline
  end

  get "/user_profile" do
    @timeline = Weibo::Base.new(authorize(Weibo::Config.api_key, Weibo::Config.api_secret)).user_timeline
    haml :user_profile
    
  end

  get "/repost" do
    puts
    puts PATH
    puts
    oauth = authorize(Weibo::Config.api_key, Weibo::Config.api_secret)
    File.open("#{APP_DIR}/../tweetid","w") do |f|
      f.puts(JSON.parse(Net::HTTP.get_response(URI.parse(PATH)).body)[0]['id'])
    end
    JSON.parse(Net::HTTP.get_response(URI.parse(PATH+"&since_id=#{startid}")).body).each do |t|
      if t['retweeted_status']
        text = {
                 :status => URI.encode(getfriends(oauth, YAYAID, 5))
               }
        tweet_id = t['retweeted_status']['id'].to_s
        sender = t['retweeted_status']['user']['id'].to_s
        begin
          Weibo::Base.new(oauth).friendship_create(sender)
          puts text.inspect
          Weibo::Base.new(oauth).repost(tweet_id,text)
        rescue
        end
        sleep 60
      end
    end
    redirect "/"
  end

  get "/login" do
    oauth = Weibo::OAuth.new(Weibo::Config.api_key, Weibo::Config.api_secret)
    request_token = oauth.consumer.get_request_token
  
    session[:rtoken], session[:rsecret] = request_token.token, request_token.secret
    redirect "#{request_token.authorize_url}&oauth_callback=http://#{request.env["HTTP_HOST"]}/callback"
  end
  
  post '/update' do
    Weibo::Base.new(authorize(Weibo::Config.api_key, Weibo::Config.api_secret)).update(params[:update])
    redirect "/friends_timeline"
  end
  
  get '/connect' do
    oauth = Weibo::OAuth.new(Weibo::Config.api_key, Weibo::Config.api_secret)
    request_token = oauth.consumer.get_request_token
  
    session[:rtoken], session[:rsecret] = request_token.token, request_token.secret
    redirect "#{request_token.authorize_url}&oauth_callback=http://#{request.env["HTTP_HOST"]}/callback"
  end
  
  
  get '/callback' do
    oauth = Weibo::OAuth.new(Weibo::Config.api_key, Weibo::Config.api_secret)
    oauth.authorize_from_request(session[:rtoken], session[:rsecret], params[:oauth_verifier])
    session[:rtoken], session[:rsecret] = nil, nil
    session[:atoken], session[:asecret] = oauth.access_token.token, oauth.access_token.secret
    redirect "/user_profile"
  end
  
  get '/logout' do
    session[:atoken], session[:asecret] = nil, nil
    redirect "/"
  end
  
  get '/screen.css' do
    content_type 'text/css'
    sass :screen
  end
#end
