namespace :rabbitmq do
  desc "Setup routing"
  task :setup do
    require "bunny"

    conn = Bunny.new(host: 'localhost')
    conn.start

    ch = conn.create_channel

    # get or create exchange
    x = ch.fanout("notification.exchange", durable: true)

    # get or create queue (note the durable setting)
    q = ch.queue("notification.queue", durable: true)

    # bind queue to exchange
    q.bind("notification.exchange")

    conn.close
  end
end
