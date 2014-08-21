require 'json'

class PushController < ApplicationController
  skip_before_filter  :verify_authenticity_token

  def send_push
    # PushWorker.perform_async("Message received from Bob", "4bc866df0385648104ca9a55cc5a8212c18b4900f7d0d2838d45f6895792f06e")
    # 5.times do
    #   # PushWorker.perform_async("{\"aps\" : { \"alert\" : \"Message received from Bob\" }}", "4bc866df0385648104ca9a55cc5a8212c18b4900f7d0d2838d45f6895792f06e")
    #   PushWorker.perform_async("Message received from Bob", "5bc866df0385648104ca9a55cc5a8212c18b4900f7d0d2838d45f6895792f06e")
    # end
    type = params["type"]
    if type == "iOS"
      alert = params["alert"]
      token = params["push_token"]
      badge = params["badge"]
      properties = JSON.parse(params["params"])
      PushWorker.perform_async(alert, token, badge, properties)
    end

    respond_to do |format|
      format.json
    end
  end
end
