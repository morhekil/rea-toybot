require 'spec/spec_helper'
require 'lib/toybot/engine'

describe 'Toybot Engine' do

  # We use 5x3 board for our tests
  before do
    @toybot = Toybot::Engine.new(5, 3)
  end

  describe 'initialization' do
    it 'should remember dimensions of the board' do
      @toybot.board_width.should == 5
      @toybot.board_height.should == 3
    end

    it 'should start in inactive state' do
      @toybot.state.should == 'inactive'
    end

    it 'should start with nil coordinates and orientations' do
      @toybot.posx.should be_nil
      @toybot.posy.should be_nil
      @toybot.dir.should be_nil
    end
  end

  describe 'commands execution' do
    it 'should fire relevant event if defined' do
      args = %w{one two three}
      @toybot.should_receive(:boo_command).once.with(*args)
      @toybot.execute('boo', args)
    end

    it 'should throw an error if the command is unknown' do
      expect { @toybot.execute('boom', nil) }.to throw_symbol(:error)
    end
  end

  describe 'PLACE command' do
    def docmd(args)
      @toybot.execute('place', args)
      @toybot
    end

    it 'should be known to the engine' do
      @toybot.should respond_to(:place_command)
    end

    describe 'with valid arguments' do
      before do
        docmd(%w{1 2 north})
      end

      it 'should set the position' do
        @toybot.pos.should == [1, 2]
      end

      it 'should set the direction' do
        @toybot.dir.should_not be_nil
      end

      it 'should activate Toybot' do
        @toybot.should be_active
      end
    end

    describe 'with invalid arguments' do
      before do
        docmd(%w{100 -100 inside})
      end

      it 'should stay in inactive state' do
        @toybot.state.should == 'inactive'
      end

      it 'should not change the coordinates' do
        @toybot.pos.should == [nil, nil]
      end

      it 'should not change the direction' do
        @toybot.dir.should be_nil
      end
    end

    describe 'arguments validation' do

      def validate(args)
        transition = double('transition', :args => args)
        @toybot.send(:validate_position, transition)
      end

      it 'should fail when direction is invalid' do
        expect { validate(%w{1 1 inside}) }.to throw_symbol(:halt)
      end

      it 'should fail when new position is outside the board' do
        expect { validate(%w{100 -5 north}) }.to throw_symbol(:halt)
      end

      it 'should pass with coordinates are on the board and direction is valid' do
        %w{north east west south}.each do |dir|
          expect { validate(%w{1 1} + [dir]) }.not_to throw_symbol(:halt)
        end
      end

    end

  end

end
