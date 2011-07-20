require 'rb-readline'

module Toybot

  # Input module takes care of reading commands and passing them
  # over to processing. Currently commands can be entered interactively
  # using readline-powered interface, or given as stdin stream.
  #
  # Reading loop starts by calling Toybot::Input.start method, that
  # expects a block to be supplied. The block will be called with two
  # arguments, first of them will contain downcased command string,
  # and the second one - an array of arguments.
  #
  # Example:
  #
  # Toybot::Input.start do |cmd, args|
  #   $stdout.puts "CMD: #{cmd.inspect}, ARGS: #{args.inspect}"
  # end
  #
  module Input
    extend self

    # We start input processing by reading the input line-by-line,
    # splitting the lines into commands and arguments, and passing
    # the result over to a block given by the caller
    def start(&block)
      while line = next_line
        cmd, *args = parse(line)
        cmd && !cmd.empty? ?
          # If the command is not empty - invoke the handler
          block.call(cmd, args) :
          # Empty command ends the processing loop
          break
      end
    end

    protected

    # Parses the input line, converting the case and splitting
    # the line into a command and it's arguments, returning them
    # as an array
    def parse(line)
      line.downcase.split(' ')
    end

    # This method reads the next line from our input stream. It can be
    # either stdin - in this case we just read it line by line,
    # or it can be a terminal shell - then we use Readline to read
    # commands interactively
    def next_line
      $stdin.tty? ?
        Readline.readline('> ', true) :
        $stdin.gets
    end

  end
end
