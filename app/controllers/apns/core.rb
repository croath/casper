module APNSPush
  require 'socket'
  require 'openssl'
  require 'singleton'

  attr_accessor :host, :port, :cert, :pass

  def initialize
    @host = 'gateway.sandbox.push.apple.com'
    @port = 2195
    @cert = Rails.root.join('cert', 'dev.pem').to_s
    @pass = nil
  end
end

require 'base64'

class PushConnection
  include APNSPush
  include Singleton

  @ssl = nil
  @sock = nil

  def connect
    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(@cert))
    context.key  = OpenSSL::PKey::RSA.new(File.read(@cert), @pass)

    @sock         = TCPSocket.new(@host, @port)
    @ssl          = OpenSSL::SSL::SSLSocket.new(@sock, context)

    @ssl.connect

    t1 = Thread.new do
      begin
        result = @ssl.read_nonblock(8)
        self.handle_error(result)
      rescue IO::WaitReadable
        IO.select([@ssl])
        retry
      rescue IO::WaitWritable
        IO.select(nil, [@ssl])
        retry
      end
    end

    puts 'listening...'
  end

  def disconnect
    @ssl.close
    @sock.close
  end

  def self.instance
    @@instance ||= new
  end

  def initialize
    super
    puts "host: " + @host
  end

  def send_push(push_array)
    puts 'send start'
    @ssl.write(self.push_data(push_array))
    puts 'send success'
  end

  def handle_error(err)
    err.strip!
    command, status, identifier = err.unpack('CCA*')
    puts "!!!ERROR!!! cmd = #{command} status = #{status} id = #{Base64.encode64(identifier)}"
    retry_array = PushNotification.get_all_after_id(Base64.encode64(identifier))

    self.disconnect
    self.connect

    self.send_push(retry_array)
  end

  def push_data(push_array)

    bytes = ''

    for p in push_array
      puts p.json_dump
      data = ''
      data << [1, 32, [p.token].pack('H*')].pack("CnA*")
      data << [2, p.json_ready_for_push.bytesize, p.json_ready_for_push].pack("CnA*")
      data << [3, 4, p.binary_id].pack("CnA*")
      data << [4, 4, p.expiration].pack("CnN")
      data << [5, 1, p.priority].pack("CnC")

      bytes << ([2, data.bytesize].pack('CN') + data)
    end
    bytes
  end
end

class ConnectionService
  @@pool_count = 1

  def self.current_connection
    PushConnection.instance
  end

  def self.push_connection
    self.current_connection
  end

  @@conn = ConnectionService.push_connection
  @@conn.connect

  def self.send_push(content, token)
    p = PushNotification.new_with_infos(token, content, 0, nil)
    p.save_to_store

    @@conn.send_push([p])
  end
end
