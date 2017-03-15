require "sinatra"
require 'json'
require "bunny"
require 'haml'
$base_uri=nil
$temporaryorderlist={}
rabbitConn = Bunny.new(ENV["RABBITMQ"])
rabbitConn.start
channel=rabbitConn.create_channel
$orderExchange=channel.topic("orders")
queue = channel.queue("", :exclusive => true, :durable=>false)
queue.bind($orderExchange, :routing_key=>"create.order")
queue.subscribe(:manual_ack => true, :block => false) do |delivery_info, properties, body|
  if(not $base_uri.nil?)
    begin
      puts body
      message=JSON.parse body
      id=message["id"]
      uri=$base_uri+"/order/"+id
      if message["items"].all? { |item|item["product"].start_with?$base_uri}
        $temporaryorderlist[id]=message
        puts uri
        $orderExchange.publish('{"id":"'+id+'","uri":"'+uri+'"}', :routing_key =>"created.order")
      else
        $orderExchange.publish('{"id":"'+id+'"}', :routing_key =>"rejected.order")
      end
    rescue Exception => e
      puts e
    end
    channel.ack(delivery_info.delivery_tag)
    $orderExchange
  end
end
error do
  @e = request.env['sinatra_error']
  puts @e
  "500 server error".to_json
end

get '/order/register-hack' do
  $base_uri=request.base_url
  "OK"
end
get "/order/:id" do
  $temporaryorderlist[params['id']].to_json
end
