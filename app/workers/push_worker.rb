class PushWorker
  include Sidekiq::Worker

  def perform(content, token)
    puts "One push token : #{token}, content: #{content}"
  end
end
