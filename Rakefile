# rpush_spec = Gem::Specification.find_by_name 'rpush'
# Dir["#{rpush_spec.gem_dir}/lib/tasks/*.rake"].each { |r| load r }

namespace :rabbitmq do
  desc "Setup routing"
  task :setup do
    require "bunny"

    conn = Bunny.new({
      :host      => ENV['RABBITMQ_HOST'].strip,
      :port      => 5672,
      :ssl       => false,
      :vhost     => "/",
      :user      => ENV['RABBITMQ_USER'].strip,
      :pass      => ENV['RABBITMQ_PASS'].strip,
      :heartbeat => :server, # will use RabbitMQ setting
      :frame_max => 131072,
      :auth_mechanism => "PLAIN"
    })
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
