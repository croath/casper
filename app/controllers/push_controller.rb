class PushController < ApplicationController
  def send_push
    15000.times do
      PushWorker.perform_async("test_1", "token_1")
    end
  end
end
