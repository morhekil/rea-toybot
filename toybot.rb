#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'lib/toybot'

Toybot::Input.start do |cmd, args|
  $stdout.puts "CMD: #{cmd.inspect}, ARGS: #{args.inspect}"
end
