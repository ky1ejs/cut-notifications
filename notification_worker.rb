require 'sneakers'
require 'json'
require 'apnotic'
require 'connection_pool'

class NotificationWorker
  include Sneakers::Worker
  from_queue "notification.queue", env: nil

  DEV_POOL = Apnotic::ConnectionPool.development({cert_path: ENV['CUT_APNS_DEV_PEM']}, size: 5)
  PROD_POOL = Apnotic::ConnectionPool.new({cert_path: ENV['CUT_APNS_PROD_PEM']}, size: 5)

  def work(raw_event)
    payload = JSON.parse raw_event

    token = payload['token']
    message = payload['message']
    is_dev_token = payload['is_dev_token']

    if token == nil ||
      !token.is_a?(String) ||
      message == nil ||
      !message.is_a?(String) ||
      is_dev_token == nil ||
      !(is_dev_token.is_a?(TrueClass) || is_dev_token.is_a?(FalseClass))
      ack!
      puts '################################'
      puts "JSON payload invalid"
      puts "token         - #{token}"
      puts "message       - #{message}"
      puts "is_dev_token  - #{is_dev_token}"
      puts '################################'
      return
    end

    puts payload

    pool = is_dev_token ? DEV_POOL : PROD_POOL

    pool.with do |conn|
      notification       = Apnotic::Notification.new(token)
      notification.alert = message
      notification.sound = 'default'

      response = conn.push(notification)

      if response == nil
        puts "Timeout sending a push notification"
      else
        puts "Success     #{response.ok?}"
        puts "Status Code #{response.status}"
      end
    end
  end
end
