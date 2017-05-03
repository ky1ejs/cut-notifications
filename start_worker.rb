#!/usr/bin/env ruby
require 'bundler/setup'
root = File.expand_path('', File.dirname(__FILE__))
$: << root
require 'notification_worker.rb'
require 'sneakers/runner'
require 'logger'

user = ENV['RABBITMQ_USER'].strip
pass = ENV['RABBITMQ_PASS'].strip
host = ENV['RABBITMQ_HOST'].strip

puts "amqp://#{user}:#{pass}@#{host}:5672"

Sneakers.configure  :amqp => "amqp://#{user}:#{pass}@#{host}:5672",
                    :daemonize => false,
                    :log => STDOUT

Sneakers.logger.level = Logger::INFO

r = Sneakers::Runner.new([ NotificationWorker ])
r.run
