class PushWorker
  include Sidekiq::Worker

  def perform(content, token)
    APNSPush::ConnectionService.send_push(content, token)
  end
end
