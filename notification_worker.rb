require 'sneakers'
require 'json'
require 'houston'

class NotificationWorker
  include Sneakers::Worker
  from_queue "notification.queue", env: nil

  def self.ios_dev_connecton
    return @ios_dev_connecton if !@ios_dev_connecton.nil?
    certificate = File.read(ENV[:CUT_APNS_DEV_PEM])
    passphrase = ''
    @ios_dev_connecton = Houston::Connection.new(Houston::APPLE_DEVELOPMENT_GATEWAY_URI, certificate, nil)
    @ios_dev_connecton.open
    return @ios_dev_connecton
  end

  def self.ios_prod_connecton
    return @ios_prod_connecton if !@ios_prod_connecton.nil?
    certificate = File.read(ENV[:CUT_APNS_PROD_PEM])
    passphrase = ''
    @ios_prod_connecton = Houston::Connection.new(Houston::APPLE_PRODUCTION_GATEWAY_URI, certificate, passphrase)
    @ios_prod_connecton.open
    return @ios_prod_connecton
  end

  def work(raw_event)
    payload = JSON.parse raw_event

    notification = Houston::Notification.new(device: payload['token'])
    notification.alert = payload['message']

    # Notifications can also change the badge count, have a custom sound, have a category identifier, indicate available Newsstand content, or pass along arbitrary data.
    notification.badge = 0
    notification.sound = 'default'
    # notification.category = ''
    # notification.content_available = true
    # notification.mutable_content = true
    # notification.custom_data = { foo: 'bar' }

    conn = payload['is_dev_token'] ? self.class.ios_dev_connecton : self.class.ios_prod_connecton
    conn.write(notification.message)

    ack!
  end
end
