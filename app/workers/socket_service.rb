require 'socket'
require 'json'

class SocketService
  include Singleton

  def initialize
    if @server == nil
      @server = TCPServer.new 9092
      puts 'tcp start 9092'
    end
  end

  def start_server
    t1 = Thread.new do
      loop {
        Thread.start(@server.accept) do |client|
          client.puts('eureka')
          loop {
            message = client.gets
            if message != nil
              parse_client_message(message)
            end
          }
        end
      }
    end
  end

  def parse_client_message(msg)
    begin
      msg_hash = JSON.parse(msg)
      msg_hash["notifications"].each do |noti_hash|
        type = noti_hash["type"]
        if type == "iOS"
          alert = noti_hash["alert"]
          token = noti_hash["push_token"]
          badge = noti_hash["badge"]
          properties = JSON.parse(noti_hash["params"])
          PushWorker.perform_async(alert, token, badge, properties)
        end
      end
    rescue => error
      puts error
      return
    end
  end
end
