class PushWorker
  include Sidekiq::Worker

  def perform(content, token)
    ConnectionService.send_push(content, token)
  end
end
