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

      event :block_movement do
        transition :active => :blocked
      end

      event :activate do
        transition any => :active
      end
      after_transition any => :active, :do => :check_ahead

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
      valid = valid_coordinates?(newx, newy) && DIR.include?(newdir)
      throw :halt unless valid
    end

    # Validates given coordinates to be inside the board
    def valid_coordinates?(x, y)
      (1..board_width).include?(x.to_i + 1) &&
        (1..board_height).include?(y.to_i + 1)
    end

    # Checks if there's an empty space in front of Toybot to move onto.
    # If there's none - Toybot goes into blocked state, ignoring MOVE commands
    def check_ahead
      has_space = !(pos == [0, 1] && dir == 'west')
      block_movement unless has_space
    end

  end

end
