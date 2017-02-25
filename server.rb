require "sinatra"
require 'json'
require 'haml'

error do
  @e = request.env['sinatra_error']
  puts @e
  "500 server error".to_json
end

get '/order/add-button-component' do
  haml :add_button_component
end
post '/order/add-item' do
  "TODO"
end