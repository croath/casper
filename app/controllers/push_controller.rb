class PushController < ApplicationController
  def send_push
    1.times do
      # PushWorker.perform_async("{\"aps\" : { \"alert\" : \"Message received from Bob\" }}", "4bc866df0385648104ca9a55cc5a8212c18b4900f7d0d2838d45f6895792f06e")
      PushWorker.perform_async("{\"aps\" : { \"alert\" : \"Message received from Bob\" }}", "5bc866df0385648104ca9a55cc5a8212c18b4900f7d0d2838d45f6895792f06e")
    end
  end
end
