module OauthHelper
  def authorize(key, secret)
    oauth = Weibo::OAuth.new(key, secret)
    oauth.authorize_from_access(session[:atoken], session[:asecret])
    return oauth
  end

  def getfriends(auth, userid, num)
    userlist = Weibo::Base.new(auth).friends
    users = ""
    while (num > 0)
      users << " @#{userlist[rand(userlist.length - 1)]['screen_name']}"
      num = num - 1
    end
    return users
  end
end
