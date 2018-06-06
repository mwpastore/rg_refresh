# frozen_string_literal: true
require 'mqtt'

module RgRefresh
  class PublishWrapper
    attr_reader :client, :topic, :messages

    def initialize(opts)
      @client = MQTT::Client.connect(opts.fetch(:client))
      @topic = opts.fetch(:topic)
      @messages = opts.fetch(:messages)
    end

    def transition_to(mode)
      client.publish(topic, messages.fetch(mode))
    end

    def finish
      client.disconnect
    rescue
    end
  end
end
