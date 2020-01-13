# old url's

get "/view_url/:url_id" do |env|
  env.redirect "/show_details/#{env.params.url["url_id"]}"
end
