require 'spec/spec_helper'
require 'lib/toybot/input'
require 'timeout'

describe Toybot::Input do

  before do
    # Shortcut to the target module
    @input = Toybot::Input
  end

  describe 'reading loop' do

    # Helper method that starts the reading loop under timeout,
    # to make sure the tests don't hand indefinitely if we're stuck
    # waiting for the input or inside an indefinite reading loop
    def do_start(&block)
      Timeout.timeout(5) { @input.start(&block) }
    rescue Timeout::Error
      fail "Stuck in the reading loop"
    end

    # Mock collector and handler to check expectations on command-handling
    # block
    before do
      @collector = double('collector')
      @handler = Proc.new { |cmd, args| @collector.ping(cmd, args) }
    end

    describe "every line" do

      before do
        @commands = %w{FIRST SECOND LAST}
      end

      it 'should be read until the empty one' do
        @input.should_receive(:next_line).exactly(4).times.
          and_return { @commands.shift }
        do_start {}
      end

      it 'should be parsed' do
        @input.stub(:next_line).and_return { @commands.shift }
        @commands.each do |cmdline|
          @input.should_receive(:parse).ordered.with(cmdline).and_return('boo')
        end
        do_start {}
      end

      it 'should be passed to the handler for procesing if not empty' do
        @input.stub(:next_line).and_return { @commands.shift }
        @collector.should_receive(:ping).exactly(3).times.with(
          an_instance_of(String), an_instance_of(Array)
        )
        do_start &@handler
      end

      it 'should not be passed to the handler if empty' do
        @input.stub(:next_line).and_return(nil)
        @collector.should_receive(:ping).never
        do_start &@handler
      end

    end

    describe "line parsing" do

      it 'should downcase the string' do
        @input.send(:parse, 'COMMAND').should == %w{command}
      end

      it 'should split the line on space char and return an array' do
        @input.send(:parse, 'COMMAND ARG1,ARG2').should == %w{
          command arg1 arg2
        }
      end

    end

    describe "command and arguments" do

      def run_command(cmd)
        lines = %w{line}
        @input.stub(:next_line).and_return { lines.shift }
        @input.stub(:parse).and_return(cmd)
        do_start &@handler
      end

      it "should be a string and an empty array when there're no arguments" do
        @collector.should_receive(:ping).once.with(
          'command', []
        )
        run_command(%w{command})
      end

      it "should be a string and an array of string if there're arguments" do
        @collector.should_receive(:ping).once.with(
          'command', ['arg1', 'arg2']
        )
        run_command(%w{command arg1 arg2})
      end

    end

  end

  describe "getting lines" do

    it "from stdin if we don't have a terminal" do
      $stdin.stub(:tty? => false)
      Readline.should_receive(:readline).never
      $stdin.should_receive(:gets).once
      @input.send(:next_line)
    end

    it "from Readline if we're inside a terminal" do
      $stdin.stub(:tty? => true)
      Readline.should_receive(:readline).once
      $stdin.should_receive(:gets).never
      @input.send(:next_line)
    end

  end

end
