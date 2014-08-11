module APNSPush
  require 'socket'
  require 'openssl'
  require 'singleton'

  attr_accessor :host, :port, :cert, :pass

  def initialize
    @host = 'gateway.sandbox.push.apple.com'
    @port = 2195
    @cert = nil
    @pass = nil
  end
end

class PushConnection
  include APNSPush
  include Singleton

  @ssl = nil
  @sock = nil

  def connect
    @ssl.connect
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
    puts "I'm being initialized!!!"
    puts "host: " + @host

    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(@cert))
    context.key  = OpenSSL::PKey::RSA.new(File.read(@cert), @pass)

    @sock         = TCPSocket.new(@host, @port)
    @ssl          = OpenSSL::SSL::SSLSocket.new(@sock, context)
  end

  def push(content, token)
    puts 'send'
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
    puts "conn = " + @@conn.to_s
    @@conn.send_push(content, token)
  end
end
