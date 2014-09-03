module APNSPush
  require 'socket'
  require 'openssl'
  require 'singleton'

  attr_accessor :host, :port, :cert, :pass

  def initialize
    @sandbox_host = 'gateway.sandbox.push.apple.com'
    @sandbox_port = 2195
    @sandbox_cert = Rails.root.join('cert', 'dev.pem').to_s
    @sandbox_pass = nil

    @production_host = 'gateway.push.apple.com'
    @production_port = 2195
    @production_cert = Rails.root.join('cert', 'production.pem').to_s
    @production_pass = nil
  end
end

require 'base64'
require 'thread'

class PushConnection
  include APNSPush

  @ssl = nil
  @sock = nil

  def connect
    context      = OpenSSL::SSL::SSLContext.new

    if @sandbox
      context.cert = OpenSSL::X509::Certificate.new(File.read(@sandbox_cert))
      context.key  = OpenSSL::PKey::RSA.new(File.read(@sandbox_cert), @sandbox_pass)
    else
      context.cert = OpenSSL::X509::Certificate.new(File.read(@production_cert))
      context.key  = OpenSSL::PKey::RSA.new(File.read(@production_cert), @production_pass)
    end

    if @sandbox
      @sock        = TCPSocket.new(@sandbox_host, @sandbox_port)
    else
      @sock        = TCPSocket.new(@production_host, @production_port)
    end

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
  end

  def self.instance
    @@instance ||= new
  end

  def initialize(identifier, sandbox = true)
    super()

    @semaphore = Mutex.new
    @connection_id = identifier
    @sandbox = sandbox
  end

  def send_push(push_array)
    puts 'send start'
    @semaphore.synchronize {
      tries = 0
      begin
        @ssl.write(self.push_data(push_array))
      rescue => err
        puts err
        self.connect
        tries += 1
        if tries <= 3
          retry
        end
      end
    }
    puts 'send success'
  end

  def handle_error(err)
    err.strip!
    command, status, identifier = err.unpack('CCA*')
    puts "!!!ERROR!!! cmddd = #{command} status = #{status} id = #{Base64.encode64(identifier)}"

    puts "status = #{status} fuck"

    if status.to_i == 8
      puts Base64.encode64(identifier)
      notification = self.get_from_store("#{Base64.encode64(identifier)}")
      save_invalid(notification)
    end

    retry_array = self.get_all_after_id(Base64.encode64(identifier))

    @semaphore.synchronize {
      self.connect
    }

    self.send_push(retry_array)
  end

  def push_data(push_array)

    bytes = ''

    for p in push_array
      if self.check_valid(p)
        puts p.json_dump
        data = ''
        data << [1, 32, [p.token].pack('H*')].pack("CnA*")
        data << [2, p.json_ready_for_push.bytesize, p.json_ready_for_push].pack("CnA*")
        data << [3, 4, p.binary_id].pack("CnA*")
        data << [4, 4, p.expiration].pack("CnN")
        data << [5, 1, p.priority].pack("CnC")

        bytes << ([2, data.bytesize].pack('CN') + data)
      end
    end
    bytes
  end

  def redis_noti_prefix
    "notification:q#{@connection_id}"
  end

  def redis_ids_prefix
    "ids:q#{@connection_id}"
  end

  def invalid_token_prefix
    "inv:token"
  end

  def save_invalid(notification)
    $redis.zadd(invalid_token_prefix, 1, notification.token)
  end

  def check_valid(notification)
    $redis.zscore(invalid_token_prefix, notification.token) == nil
  end

  def save_to_store(notification)
    $redis.zadd(redis_ids_prefix, (Time.now.to_f*10000).to_i, notification.identifier)
    $redis.set("#{redis_noti_prefix}:#{notification.identifier}", notification.json_dump)
  end

  def get_all_after_id(identifier)
    timestamp = $redis.zscore(redis_ids_prefix, identifier).to_i
    all_ids = $redis.zrangebyscore(redis_ids_prefix, "(#{timestamp}", "(#{(Time.now.to_f*10000).to_i}")

    id_list = Array.new
    for one_id in all_ids
      new_id = "#{redis_noti_prefix}:#{one_id}"
      id_list.push(new_id)
    end
    json_list = $redis.mget(id_list)

    obj_list = Array.new
    for json in json_list
      obj_list.push(PushNotification.new_with_json(JSON.parse(json)))
    end

    obj_list
  end

  def get_from_store(identifier)
    json = $redis.get("#{redis_noti_prefix}:#{identifier}")
    p = PushNotification.new_with_json(JSON.parse(json))
    p
  end
end
