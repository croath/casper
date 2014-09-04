require 'socket'
require 'json'

class SocketService
  include Singleton

  def initialize
    if @server == nil
      begin
        @server = TCPServer.new 9092
        puts 'tcp start 9092'
      rescue => err
        puts err
      end
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

          @error = Array.new

          if token.nil? || token.length != 64
            @error << "incorrect token"
          end

          unless badge.is_i? && badge.to_i > 0 && badge.to_i <= 99999
            @error << "incorrect badge"
          end

          if alert.length > 50
            @error << "alert text too long"
          end

          properties = nil

          begin
            properties = JSON.parse(noti_hash["params"])
          rescue
            @error << "bad json"
          end

          if !properties.nil? && properties.length > 200
            @error << "properties text too long"
          end

          unless @error.count > 0
            PushWorker.perform_async(alert, token, badge, properties)
          end
        end
      end
    rescue => error
      puts error
      return
    end
  end
end
