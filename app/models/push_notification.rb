require 'openssl'
require 'json'
require 'base64'

class PushNotification
  attr_accessor :token, :identifier, :content, :badge, :property

  def self.new_with_infos(token, content, badge = 0, property = nil)
    noti = PushNotification.new
    noti.token = token.gsub(/[\s|<|>]/,'')
    noti.content = content
    noti.badge = badge
    noti.property = property
    noti.identifier = Base64.encode64(OpenSSL::Random.random_bytes(4))
    noti
  end

  def self.new_with_json(json_hash)
    noti = PushNotification.new
    noti.token = json_hash["token"]
    noti.content = json_hash["content"]
    noti.badge = json_hash["badge"]
    noti.property = json_hash["property"]
    noti.identifier = json_hash["identifier"]
    noti
  end

  def json_dump
    json_hash = {:token => @token, :content => @content, :badge => @badge, :property => @property, :identifier => @identifier}
    json_hash.to_json
  end

  def json_ready_for_push
    json_hash = {:aps => {:alert => @content, :badge => @badge}, :property => @property}
    json_hash.to_json
  end

  def self.get_from_store(identifier)
    json = $redis.get("notification:q0:#{identifier}")
    PushNotificaion.new_with_json(json)
  end

  def self.get_all_after_id(identifier)
    timestamp = $redis.zscore("ids:q0", identifier).to_i
    all_ids = $redis.zrangebyscore("ids:q0", "(#{timestamp}", "+inf")

    id_list = Array.new
    for one_id in all_ids
      new_id = "notification:q0:#{one_id}"
      id_list.push(new_id)
    end
    json_list = $redis.mget(id_list)

    obj_list = Array.new
    for json in json_list
      obj_list.push(PushNotification.new_with_json(JSON.parse(json)))
    end

    obj_list
  end

  def save_to_store
    $redis.zadd("ids:q0", (Time.now.to_f*10000).to_i, @identifier)
    $redis.set("notification:q0:#{@identifier}", self.json_dump)
  end

end
