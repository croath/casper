require 'json'

class String
  def is_i?
    !!(self =~ /\A[-+]?[0-9]+\z/)
  end
end

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

      @error = Array.new

      if token.nil? || token.length != 64
        @error << "incorrect token"
      end

      unless badge.is_i? && badge.to_i > 0 && badge.to_i <= 99999
        @error << "incorrect badge"
      end

      if alert.length > 50
        @error << "alert text too long"
      end

      if properties.length > 200
        @error << "properties text too long"
      end

      unless @error.count > 0
        PushWorker.perform_async(alert, token, badge, properties)
      end
    end

    @count = 1

    respond_to do |format|
      if @error.count > 0
        format.json { render template: 'push/send_push.json.jbuilder', status: 404 }
      else
        format.json { render template: 'push/send_push.json.jbuilder', status: 200 }
      end
    end
  end
end
