require 'spec/spec_helper'
require 'lib/toybot/engine'

describe 'Toybot Engine' do

  # We use 5x3 board for our tests
  before do
    @toybot = Toybot::Engine.new(5, 3)
  end

  it 'should remember dimensions of the board' do
    @toybot.board_width.should == 5
    @toybot.board_height.should == 3
  end

  it 'should start in inactive state' do
    @toybot.state.should == 'inactive'
  end

end
