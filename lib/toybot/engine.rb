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
    # Output object (should respond to :<< ), default is $stdout
    attr_accessor :output
    # Toybot's position - possible coordinates are 0..(board_size-1)
    attr_accessor :posx, :posy
    # Toybot's orientation
    attr_accessor :dir

    # Valid directions
    Directions = %w{north east south west}

    state_machine :state, :initial => :inactive do
      # Stable states
      state :inactive, :active, :blocked
      # Transient states
      state :positioning, :turning_left, :turning_right, :moving

      # Command-triggered events
      event :place_command do
        transition any => :positioning
      end
      before_transition any => :positioning, :do => :validate_position
      after_transition any => :positioning, :do => :place

      event :move_command do
        transition :active => :moving
      end
      after_transition any => :moving, :do => :move_ahead

      event :left_command do
        transition [:active, :blocked] => :turning_left
      end
      after_transition any => :turning_left, :do => :turn_left

      event :right_command do
        transition [:active, :blocked] => :turning_right
      end
      after_transition any => :turning_right, :do => :turn_right

      event :report_command do
        transition [:active, :blocked] => :reporting
      end
      after_transition any => :reporting, :do => :report

      # Block movement should be triggered when there's no empty space ahead -
      # in this case Toybot goes into a blocked state, and ignores all MOVE commands
      # until he's repositioned
      event :block_movement do
        transition :active => :blocked
      end

      # Activate event is being triggered after any valid action, and will put
      # Toybot into either active or blocked states, depending on the availability
      # of free space ahead of him
      event :activate do
        transition any => :active
      end
      after_transition any => :active, :do => :check_ahead

    end

    # Constructor takes board's width and height as it's arguments -
    # those will be the limits for Toybot's movements
    def initialize(width, height, output = $stdout)
      @board_width = width
      @board_height = height
      @output = output
      super()
    end

    def execute(cmd, args)
      event_name = "#{cmd}_command".to_sym
      throw :error, 'Invalid command' unless respond_to?(event_name)
      send(event_name, *args)
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
      valid = valid_coordinates?(newx, newy) && Directions.include?(newdir.to_s)
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
      block_movement unless valid_coordinates?(*coords_ahead)
    end

    # Moves Toybot one step ahead. We do not check legality of the move here,
    # as it should be enforced by state machine's guard conditions, and if the move
    # is illegal - Toybot goes into blocked state and doesn't respond to MOVE commands
    def move_ahead
      @posx, @posy = coords_ahead
      activate
    end

    # Calculates the next coordinates one step ahead of given position and direction.
    # To calculate offsets for X and Y we get the index of the direction
    # (i.e. north = 0, east = 1, south = 2 and west = 3) and use it as a basis for x/y calculations
    def coords_ahead
      dx = (dir_index - 2).remainder(2).to_i
      dy = (dir_index - 1).remainder(2).to_i
      [posx - dx, posy - dy]
    end

    # Calculated index of the current direction of the Toybot
    def dir_index
      Directions.index(dir.to_s)
    end

    # Turns ToyBot left
    def turn_left
      @dir = Directions[dir_index - 1] || Directions.last
      activate
    end

    # Turns ToyBot right
    def turn_right
      @dir = Directions[dir_index + 1] || Directions.first
      activate
    end

    # Return ToyBot's current position and direction
    def report
      @output << "#{posx},#{posy},#{dir.to_s.upcase}"
    end

  end

end
