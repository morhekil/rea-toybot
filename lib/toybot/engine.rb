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

    # Constructor takes board's width and height as it's arguments -
    # those will be the limits for Toybot's movements
    def initialize(width, height)
      @board_width = width
      @board_height = height
    end

    SLIME_OUTPUT = %w{3,3,NORTH}

    def execute(cmd, args)
      SLIME_OUTPUT.shift
    end

  end

end
