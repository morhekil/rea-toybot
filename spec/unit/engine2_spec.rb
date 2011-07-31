require 'spec/spec_helper'
require 'lib/toybot/engine'

describe 'Toybot Engine' do

  # Memoized output buffer, that we can check
  # in the specs if needed
  let(:output) { double('output', :puts => nil) }

  # Default Toybot Engine - we use 5x3 board for our tests
  let(:engine) { Toybot::Engine.new(5, 3, output) }

  # Default subject is the engine itself
  subject { engine }

  # Helper method to set Toybot into a given position and state
  def toybot_at(x, y, dir, state = nil)
    subject.posx = x
    subject.posy = y
    subject.dir = dir
    subject.activate unless state
    subject.state = state if state
    subject
  end

  describe 'when first created' do
    it                 { should be_inactive }
    its(:board_width)  { should == 5}
    its(:board_height) { should == 3}
    its(:posx)         { should be_nil }
    its(:posy)         { should be_nil }
    its(:dir)          { should be_nil }
  end

  describe 'commands execution' do

    context 'fires an event for known commands' do
      let(:args) { %w{one two three} }
      after { subject.execute('boo', args) }

      it { subject.should_receive(:boo_command).once.with(*args) }
    end

    it 'throws an error for unknown commands' do
      expect { subject.execute('boom', nil) }.to throw_symbol(:error)
    end
  end

  describe 'protocol' do
    %w{place report}.each do |cmd|
      it { should respond_to(:"#{cmd}_command") }
    end
  end

  describe 'position validation' do
    let(:args) { [] }
    subject do
      transition = double('transition', :args => args)
      engine.send(:validate_position, transition)
    end

    context 'when the direction is invalid' do
      let(:args) { %w{1 1 inside} }
      it { expect{subject}.to throw_symbol(:halt) }
    end

    context 'when new position is outside the board' do
      let(:args) { %w{100 -5 north} }
      it { expect{subject}.to throw_symbol(:halt) }
    end

    context 'when new position is valid' do
      %w{north east west south}.each do |dir|
        context "when the direction is #{dir}" do
          let(:args) { %w{1 1} + [dir] }
          it { expect{subject}.not_to throw_symbol(:halt) }
        end
      end
    end

  end

  describe 'PLACE command' do
    let(:args) { nil }
    subject { engine.execute('place', args); engine }

    context 'with valid arguments' do
      let(:args) { %w{1 0 north} }

      its(:pos) { should == [1, 0] }
      its(:dir) { should_not be_nil }
    end

    context 'with empty space ahead' do
      let(:args) { %w{1 0 north} }
      it { should be_active }
    end

    context 'with no space ahead' do
      let(:args) { %w{1 0 south} }
      it { should be_blocked }
    end

    context 'with invalid arguments' do
      let(:args) { %w{100 -100 inside} }

      it  { should be_inactive }
      its(:pos) { should == [nil, nil] }
      its(:dir) { should be_nil }
    end

  end

end
