# old url's

get "/show_details/:url_id" do |env| # old
  env.redirect "/show_tag_details/#{env.params.url["url_id"]}"
end

get "/view_url/:url_id" do |env| # old
  env.redirect "/movie/#{env.params.url["url_id"]}/name"
end

