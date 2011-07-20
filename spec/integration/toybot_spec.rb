require 'spec/spec_helper'
require 'lib/toybot'

describe 'ToyBot scenarios' do

  # Helper method to run the scenario file given as it's
  # argument. Expects toybot engine to be available as @toybot,
  # and retuns engine's output as an array of strings
  def scenario(filename)
    File.open(File.join('spec', 'data', *filename.flatten)) do |f|
      response = f.each_line.collect do |line|
        cmd, *args = Toybot::Input.send(:parse, line)
        @toybot.execute(cmd, args)
      end.compact
    end
  end

  before do
    # Setting up an instance of array responding to IO-like #puts calls, to be used
    # as an output target for Toybot
    @output = []
    @output.instance_eval do
      def puts(line); self << line; end
    end
  end

  context 'on 5x5 board:' do
    before do
      @toybot = Toybot::Engine.new(5, 5, @output)
    end

    it 'MOVEs correctly inside the board' do
      scenario(%w{5x5 moving_inside.txt})
      @output.should == %w{3,3,NORTH}
    end

    it 'ignores MOVEs putting Toybot outside the board' do
      scenario(%w{5x5 moving_outside.txt})
      @output.should == %w{0,3,WEST}
    end

    it 'can be PLACEd twice' do
      scenario(%w{5x5 placing_twice.txt})
      @output.should == %w{3,3,SOUTH}
    end

    it 'ignores PLACE commands putting Toybot outside the board' do
      scenario(%w{5x5 placing_outside.txt})
      @output.should == %w{3,1,SOUTH}
    end

    it 'ignores everything until it is PLACEd correctly' do
      scenario(%w{5x5 misplacing.txt})
      @output.should == %w{2,4,NORTH}
    end
  end

  # Running a complex test on 3x3 board as a proof of concept
  context 'on 3x3 board' do
    before do
      @toybot = Toybot::Engine.new(3, 3, @output)
    end

    it 'behaves properly' do
      scenario(%w{3x3 complex.txt})
      @output.should == %w{1,1,EAST}
    end

    it 'can REPORT any number of times' do
      scenario(%w{3x3 reporting_times.txt})
      @output.should == %w{1,1,EAST 2,2,NORTH 0,2,WEST}
    end
  end

end
