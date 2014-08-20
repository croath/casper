class PushWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 0
  def perform(content, token, badge, params)
    ConnectionService.send_push(content, token, badge, params)
  end
end
