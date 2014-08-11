class PushController < ApplicationController
  def send_push
    5.times do
      PushWorker.perform_async("test_1", "token_1")
    end
  end
end
