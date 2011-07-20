require 'spec/spec_helper'
require 'lib/toybot'

describe 'ToyBot scenarios' do

  # Helper method to run the scenario file given as it's
  # argument. Expects toybot engine to be available as @toybot,
  # and retuns engine's output as an array of strings
  def scenario(filename)
    File.open(File.join('spec', 'data', *filename.flatten)) do |f|
      response = f.each_line.collect do |line|
        cmd, args = Toybot::Input.send(:parse, line)
        @toybot.execute(cmd, args)
      end.compact
    end
  end

  context 'on 5x5 board' do
    before do
      @toybot = Toybot::Engine.new(5, 5)
    end

    it 'moves correctly inside the board' do
      scenario(%w{5x5 moving_inside.txt}).should == %w{3,3,NORTH}
    end

  end

end
