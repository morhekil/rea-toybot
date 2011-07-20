require 'state_machine'

module Toybot

  # Engine class implements Toybot's state and movement logic.
  # The size of the board Toybot is being placed onto should be given
  # as the arguments to Engine's constructor, and subsequent commands
  # passed over to Engine#execute.
  #
  # Toybot starts in out-of-board state, and it needs to be placed
  # with PLACE commands before any movement commands will take effect.
  class Engine

    # Board's dimensions
    attr_accessor :board_width, :board_height
    # Toybot's position - possible coordinates are 0..(board_size-1)
    attr_accessor :posx, :posy
    # Toybot's orientation
    attr_accessor :dir

    # Valid directions
    DIR = %w{north east south west}

    state_machine :state, :initial => :inactive do
      # Stable states
      state :inactive, :active, :blocked
      # Transient states
      state :positioning, :turning_left, :turning_right, :moving

      event :place_command do
        transition any => :positioning
      end
      before_transition any => :positioning, :do => :validate_position
      after_transition any => :positioning, :do => :place

      event :activate do
        transition any => :active
      end

    end

    # Constructor takes board's width and height as it's arguments -
    # those will be the limits for Toybot's movements
    def initialize(width, height)
      @board_width = width
      @board_height = height
      super()
    end

    SLIME_OUTPUT = %w{3,3,NORTH}

    def execute(cmd, args)
      event_name = "#{cmd}_command".to_sym
      throw :error, 'Invalid command' unless respond_to?(event_name)
      send(event_name, *args)

      SLIME_OUTPUT.shift
    end

    # Returns an array of [posx, posy] for easy access
    def pos
      [posx, posy]
    end

    protected

    # Executes PLACE command, updating Toybot's coordinates and direction
    def place(transition)
      newx, newy, newdir = transition.args
      @posx = newx.to_i
      @posy = newy.to_i
      @dir = newdir
      activate
    end

    # Validates new position given to the PLACE command
    def validate_position(transition)
      newx, newy, newdir = transition.args
      valid = (0..(board_width-1)).include?(newx.to_i)
      valid &&= (0..(board_height-1)).include?(newy.to_i)
      valid &&= DIR.include?(newdir)
      throw :halt unless valid
    end

  end

end
