#!/usr/bin/env ruby
require 'bundler/setup'
root = File.expand_path('', File.dirname(__FILE__))
$: << root
require 'notification_worker.rb'
require 'sneakers/runner'
require 'logger'

Sneakers.configure  :amqp => 'amqp://guest:guest@localhost:5672',
                    :daemonize => false,
                    :log => STDOUT

Sneakers.logger.level = Logger::INFO

r = Sneakers::Runner.new([ NotificationWorker ])
r.run
