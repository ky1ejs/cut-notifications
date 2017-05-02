require 'sneakers'
require 'json'
require 'rpush'

class NotificationWorker
  include Sneakers::Worker
  from_queue "notification.queue", env: nil

  def work(raw_event)
    puts dev_rpush
    ack!
  end

  def dev_rpush
    app_name = "cut-dev"
    app = Rpush::Apns::App.find_by_name(app_name)
    return app if app.new_record?

    app.name = app_name
    app.certificate = File.read("/path/to/sandbox.pem")
    app.environment = "development"
    app.password = "certificate password"
    app.connections = 1
    app.save!

    return app
  end

  def prod_rpush
    app_name = "cut-prod"
    app = Rpush::Apns::App.find_by_name(app_name)
    return app if app.new_record?

    app.name = app_name
    app.certificate = File.read("/path/to/sandbox.pem")
    app.environment = "production"
    app.password = "certificate password"
    app.connections = 1
    app.save!
    return app
  end
end
