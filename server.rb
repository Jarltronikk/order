require "sinatra"
require 'json'
require "bunny"
require 'haml'
$base_uri=nil
rabbitConn = Bunny.new(ENV["RABBITMQ"])
rabbitConn.start
channel=rabbitConn.create_channel
$registryExchange=channel.topic("registry")
def notify_product
  if not $base_uri.nil?
    $registryExchange.publish('{"key":"buy","priority":0,"uri-template":"'+$base_uri+'/order/buy-button/?product={product}"}', :routing_key => "action.product.registration")

  end
end
queue = channel.queue("", :exclusive => true, :durable=>false)
queue.bind($registryExchange, :routing_key=>"action.product.registration.request")
queue.subscribe(:manual_ack => true, :block => false) do |delivery_info, properties, body|
  begin
    notify_product
  rescue
    #TODO
  end
  channel.ack(delivery_info.delivery_tag)
end
error do
  @e = request.env['sinatra_error']
  puts @e
  "500 server error".to_json
end

get '/order/buy-button/' do
  haml :buy_button ,:locals=>{:uri=>params['uri']}
end


get '/order/register-hack' do
  $base_uri=request.base_url
  notify_product
  "OK"
end