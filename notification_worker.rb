require 'sneakers'
require 'json'

class NotificationWorker
  include Sneakers::Worker
  from_queue "notification.queue", env: nil

  def work(raw_event)
    puts JSON.parse(raw_event)
    ack!
  end
end
