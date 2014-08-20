require 'openssl'
require 'json'
require 'base64'

class PushNotification
  attr_accessor :token, :identifier, :content, :badge, :property, :expiration, :priority

  def self.new_with_infos(token, content, badge = 0, property = nil)
    noti = PushNotification.new
    noti.token = token.gsub(/[\s|<|>]/,'')
    noti.content = content
    noti.badge = badge
    noti.property = property
    noti.identifier = Base64.encode64(OpenSSL::Random.random_bytes(4))
    noti.expiration = 0
    noti.priority = 10
    noti
  end

  def self.new_with_json(json_hash)
    noti = PushNotification.new
    noti.token = json_hash["token"]
    noti.content = json_hash["content"]
    noti.badge = json_hash["badge"]
    noti.property = json_hash["property"]
    noti.identifier = json_hash["identifier"]
    noti.expiration = json_hash["expiration"]
    noti.priority = json_hash["priority"]
    noti
  end

  def binary_id
    Base64.decode64(@identifier)
  end

  def json_dump
    json_hash = {:token => @token,
               :content => @content,
                 :badge => @badge,
              :property => @property,
            :identifier => @identifier,
            :expiration => @expiration,
              :priority => @priority}
    json_hash.to_json
  end

  def json_ready_for_push
    json_hash = {:aps => {:alert => @content, :badge => @badge}, :property => @property}
    json_hash.to_json
  end
end
