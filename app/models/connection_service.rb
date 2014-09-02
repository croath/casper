class ConnectionService
  @@pool_count = 3
  @@conns = Array.new

  # def self.current_connection
  #   PushConnection.instance
  # end

  def self.random_connection
    @@conns[Random.rand(@@pool_count)]
  end

  def self.internal_push(alert, token, badge, params)
    p = PushNotification.new_with_infos(token, alert, badge, params)
    conn = self.random_connection
    conn.save_to_store(p)
    conn.send_push([p])
  end

  for i in 0..(@@pool_count-1)
    conn = PushConnection.new(i, true)
    conn.connect
    @@conns << conn
  end

  def self.send_push(alert, token, badge, params)
    self.internal_push(alert, token, badge, params)
  end
end
