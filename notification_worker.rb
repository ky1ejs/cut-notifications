require 'sneakers'
require 'json'
require 'houston'
require 'connection_pool'

class NotificationWorker
  include Sneakers::Worker
  from_queue "notification.queue", env: nil

  DEV_APNS_POOL = ConnectionPool.new(:size => 5, :timeout => 300) do
    pem_path = ENV['CUT_APNS_DEV_PEM']
    puts pem_path
    certificate = File.read(pem_path)
    conn = Houston::Connection.new(Houston::APPLE_DEVELOPMENT_GATEWAY_URI, certificate, '')
    conn.open
    conn
  end

  PROD_APNS_POOL = ConnectionPool.new(:size => 5, :timeout => 300) do
    pem_path = ENV['CUT_APNS_PROD_PEM']
    puts pem_path
    certificate = File.read(pem_path)
    conn = Houston::Connection.new(Houston::APPLE_PRODUCTION_GATEWAY_URI, certificate, '')
    conn.open
    conn
  end

  def work(raw_event)
    payload = JSON.parse raw_event

    token = payload['token']
    message = payload['message']
    is_dev_token = payload['is_dev_token']

    if token == nil ||
      !token.is_a? String ||
      message == nil ||
      !message.is_a? String ||
      is_dev_token == nil ||
      !(is_dev_token.is_a? TrueClass || is_dev_token.is_a? FalseClass)
      ack!
      puts '################################'
      puts "JSON payload invalid"
      puts "token         - #{token}"
      puts "message       - #{message}"
      puts "is_dev_token  - #{is_dev_token}"
      puts '################################'
      return
    end

    pool = is_dev_token ? DEV_APNS_POOL : PROD_APNS_POOL

    pool.with do |conn|
      notification = Houston::Notification.new(device: token)
      notification.alert = message

      # Notifications can also change the badge count, have a custom sound, have a category identifier, indicate available Newsstand content, or pass along arbitrary data.
      notification.badge = 0
      notification.sound = 'default'
      # notification.category = ''
      # notification.content_available = true
      # notification.mutable_content = true
      # notification.custom_data = { foo: 'bar' }

      puts conn.write(notification.message)
      puts notification.error
    end

    ack!
  end
end
