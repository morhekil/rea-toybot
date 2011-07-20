#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'lib/toybot'

toybot = Toybot::Engine.new(5, 5)
Toybot::Input.start do |cmd, args|
  error = catch(:error) {
    toybot.execute(cmd, args)
  }
  $stdout.puts "ERR: #{error}" if error.is_a?(String)
end
