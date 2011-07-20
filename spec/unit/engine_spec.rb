require 'spec/spec_helper'
require 'lib/toybot/engine'

describe 'Toybot Engine' do

  # We use 5x3 board for our tests
  before do
    @toybot = Toybot::Engine.new(5, 3)
  end

  # Helper method to set Toybot into a given position and state
  def toybot_at(x, y, dir, state = nil)
    @toybot.posx = x
    @toybot.posy = y
    @toybot.dir = dir
    @toybot.activate unless state
    @toybot.state = state if state
    @toybot
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
      it 'should set the position' do
        docmd(%w{1 0 north})
        @toybot.pos.should == [1, 0]
      end

      it 'should set the direction' do
        docmd(%w{1 0 north})
        @toybot.dir.should_not be_nil
      end

      it 'should activate Toybot if there is empty space ahead' do
        docmd(%w{1 0 north})
        @toybot.state.should == 'active'
      end

      it 'should leave Toybot in blocked state if there is no empty space ahead' do
        docmd(%w{1 0 south})
        @toybot.state.should == 'blocked'
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

  describe 'MOVE command' do
    def docmd
      @toybot.execute('move', nil)
    end

    it 'should be known to the engine' do
      @toybot.should respond_to(:move_command)
    end

    it 'should get new coordinates and set them if Toybot is active' do
      toybot_at(1, 1, 'north')
      @toybot.should_receive(:coords_ahead).at_least(:once).and_return([2, 2])
      expect { docmd }.to change{@toybot.pos}.from([1, 1]).to([2, 2])
    end

    it 'should be ignored if Toybot is inactive' do
      @toybot.should_receive(:coords_ahead).never
      expect { docmd }.not_to change{@toybot.pos}
    end

    it 'should be ignored if Toybot is blocked' do
      toybot_at(0, 0, :west, 'blocked')
      @toybot.should_receive(:coords_ahead).never
      expect { docmd }.not_to change{@toybot.pos}
    end

    it 'should left Toybot in active state if there is more space ahead' do
      toybot_at(1, 0, :north, 'active')
      expect { docmd }.not_to change{@toybot.state}
    end

    it 'should left Toybot in blocked state if there is no space ahead' do
      toybot_at(0, 1, :south, 'active')
      expect { docmd }.to change{@toybot.state}.from('active').to('blocked')
    end

  end

  describe 'LEFT command' do
    def docmd
      @toybot.execute('left', nil)
    end

    it 'should be known to the engine' do
      @toybot.should respond_to(:left_command)
    end

    it 'should change direction counter-clockwise' do
      {
        :north => :west,
        :west => :south,
        :south => :east,
        :east => :north
      }.each_pair do |dir_old, dir_new|
        toybot_at(1, 1, dir_old)
        expect { docmd }.to change{ @toybot.dir.to_sym }.from(dir_old).to(dir_new)
      end
    end

    it 'should leave Toybot in active state if empty space is ahead' do
      toybot_at(1, 0, :south, 'blocked')
      expect { docmd }.to change{ @toybot.state }.from('blocked').to('active')
    end

    it 'should leave Toybot in blocked state if no empty space is ahead' do
      toybot_at(1, 0, :west)
      expect { docmd }.to change{ @toybot.state }.from('active').to('blocked')
    end
  end

  describe 'RIGHT command' do
    def docmd
      @toybot.execute('right', nil)
    end

    it 'should be known to the engine' do
      @toybot.should respond_to(:right_command)
    end

    it 'should change direction clockwise' do
      {
        :north => :east,
        :east => :south,
        :south => :west,
        :west => :north
      }.each_pair do |dir_old, dir_new|
        toybot_at(1, 1, dir_old)
        expect { docmd }.to change{ @toybot.dir.to_sym }.from(dir_old).to(dir_new)
      end
    end

    it 'should leave Toybot in active state if empty space is ahead' do
      toybot_at(1, 0, :south, 'blocked')
      expect { docmd }.to change{ @toybot.state }.from('blocked').to('active')
    end

    it 'should leave Toybot in blocked state if no empty space is ahead' do
      toybot_at(1, 0, :east)
      expect { docmd }.to change{ @toybot.state }.from('active').to('blocked')
    end
  end

  describe 'next coordinates calculation' do
    def get(x, y, dir)
      toybot_at(x, y, dir)
      @toybot.send(:coords_ahead)
    end

    it 'should increment Y when facing north' do
      get(1, 1, :north).should == [1, 2]
    end

    it 'should decrement Y when facing south' do
      get(1, 1, :south).should == [1, 0]
    end

    it 'should increment X when facing east' do
      get(1, 1, :east).should == [2, 1]
    end

    it 'should decrement X when facing west' do
      get(1, 1, :west).should == [0, 1]
    end

  end

end
