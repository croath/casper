class PushWorker
  include Sidekiq::Worker
  sidekiq_options :retry => 0
  def perform(content, token)
    ConnectionService.send_push(content, token)
  end
end
