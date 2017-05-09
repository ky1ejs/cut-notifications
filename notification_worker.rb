require 'sneakers'
require 'json'
require 'lowdown'
require 'connection_pool'

class NotificationWorker
  include Sneakers::Worker
  from_queue "notification.queue", env: nil

  DEV_APNS_POOL  = Lowdown::Client.production(false,  certificate: File.read(ENV['CUT_APNS_DEV_PEM']),  pool_size: 3)
  PROD_APNS_POOL = Lowdown::Client.production(true,   certificate: File.read(ENV['CUT_APNS_PROD_PEM']), pool_size: 3)

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

    pool = is_dev_token ? DEV_APNS_POOL : PROD_APNS_POOL

    begin
      pool.group do |g|
        notification = Lowdown::Notification.new(:token => token)
        notification.payload = { :alert => message, :sound => "default" }
        g.send_notification(notification) do |response|
          if response.success?
            puts "Sent notification with ID: #{notification.id}"
          else
            puts "[!] (##{response.id}): #{response}"
          end
        end
      end
    rescue Interrupt
      puts "[!] Interrupt, exiting"
    rescue Exception => e
      puts "[!] Error occurred: #{e.message}"
    end
  end
end
