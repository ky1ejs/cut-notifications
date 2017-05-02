require 'sneakers'
require 'json'
require 'houston'

class NotificationWorker
  include Sneakers::Worker
  from_queue "notification.queue", env: nil

  def self.ios_dev_connecton
    return @ios_dev_connecton if !@ios_dev_connecton.nil?
    certificate = File.read('cut-apns-dev.pem')
    passphrase = ''
    @ios_dev_connecton = Houston::Connection.new(Houston::APPLE_DEVELOPMENT_GATEWAY_URI, certificate, nil)
    @ios_dev_connecton.open
    return @ios_dev_connecton
  end

  def self.ios_prod_connecton
    return @ios_prod_connecton if !@ios_prod_connecton.nil?
    certificate = File.read('cut-apns-dev.pem')
    passphrase = ''
    @ios_prod_connecton = Houston::Connection.new(Houston::APPLE_PRODUCTION_GATEWAY_URI, certificate, passphrase)
    @ios_prod_connecton.open
    return @ios_prod_connecton
  end

  def work(raw_event)
    json = JSON.parse raw_event
    puts json
    conn = json['is_dev_token'] ? self.class.ios_dev_connecton : self.class.ios_prod_connecton

    # Environment variables are automatically read, or can be overridden by any specified options. You can also
    # conveniently use `Houston::Client.development` or `Houston::Client.production`.

    # An example of the token sent back when a device registers for notifications
    token = 'f67678a5a9567413b17059d67c4a9b67c53fa81ce681cc02975690cc53a696fa'

    # Create a notification that alerts a message to the user, plays a sound, and sets the badge on the app
    notification = Houston::Notification.new(device: token)
    notification.alert = json['message']

    # Notifications can also change the badge count, have a custom sound, have a category identifier, indicate available Newsstand content, or pass along arbitrary data.
    notification.badge = 0
    notification.sound = 'default'
    # notification.category = ''
    # notification.content_available = true
    # notification.mutable_content = true
    # notification.custom_data = { foo: 'bar' }

    conn.write(notification.message)

    ack!
  end
end
