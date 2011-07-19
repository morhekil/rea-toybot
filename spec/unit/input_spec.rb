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

    describe "every line" do

      before do
        @commands = %w{first second last}
        @collector = double('collector')
      end

      it 'should be read until the empty one' do
        @input.should_receive(:next_line).exactly(4).times.
          and_return { @commands.shift }
        do_start {}
      end

      it 'should be passed to the handler for procesing' do
        @input.stub(:next_line).and_return { @commands.shift }
        target = double('Target')
        target.should_receive(:ping).exactly(3).times.with(
          an_instance_of(String), an_instance_of(Array)
        )
        handler = Proc.new { |cmd, args| target.ping(cmd, args) }
        do_start &handler
      end

    end

    describe "commands" do

      before do
        @collector = double('collector')
        @handler = Proc.new { |cmd, args| @collector.ping(cmd, args) }
      end

      it 'should be downcased' do
        commands = ['COMMAND']
        @input.stub(:next_line).and_return { commands.shift }
        @collector.should_receive(:ping).once.with('command', [])
        do_start &@handler
      end

      it 'should be split on space char and passed with arguments' do
        commands = ['COMMAND ARG1 ARG2']
        @input.stub(:next_line).and_return { commands.shift }
        @collector.should_receive(:ping).once.with(
          'command', ['arg1', 'arg2']
        )
        do_start &@handler
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
