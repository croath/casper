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
    puts "host: " + @host

    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(@cert))
    context.key  = OpenSSL::PKey::RSA.new(File.read(@cert), @pass)

    @sock         = TCPSocket.new(@host, @port)
    @ssl          = OpenSSL::SSL::SSLSocket.new(@sock, context)
  end

  def send_push(content, token)
    puts 'start send'
    @ssl.write(self.push_data(content, token))
    puts 'end send'
  end

  def push_data(content, token)
    pt = [token.gsub(/[\s|<|>]/,'')].pack('H*')
    pm = content
    pi = OpenSSL::Random.random_bytes(4)
    pe = 0
    pr = 10

    # Each item consist of
    # 1. unsigned char [1 byte] is the item (type) number according to Apple's docs
    # 2. short [big endian, 2 byte] is the size of this item
    # 3. item data, depending on the type fixed or variable length
    data = ''
    data << [1, 32, pt].pack("CnA*")
    data << [2, pm.bytesize, pm].pack("CnA*")
    data << [3, 4, pi].pack("CnA*")
    data << [4, 4, pe].pack("CnN")
    data << [5, 1, pr].pack("CnC")

    bytes = ''
    bytes << ([2, data.bytesize].pack('CN') + data)

    puts bytes

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
    puts "conn = " + @@conn.to_s
    @@conn.send_push(content, token)
  end
end
