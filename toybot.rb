#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'lib/toybot'

width, height = case ARGV.count
                when 1
                  [ARGV.first, ARGV.first]
                when 2
                  [ARGV.first, ARGV.last]
                else
                  [5, 5]
                end

toybot = Toybot::Engine.new(width.to_i, height.to_i)
Toybot::Input.start do |cmd, args|
  error = catch(:error) {
    toybot.execute(cmd, args)
  }
  $stdout.puts "ERR: #{error}" if error.is_a?(String)
end
