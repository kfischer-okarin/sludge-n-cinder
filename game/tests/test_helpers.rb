module TestHelpers
  module DSL
    class Base
      def initialize(args)
        @args = args
        @args.tick_count = 0
      end

      def tick_count
        @args.tick_count
      end

      def safe_loop(fail_message, &block)
        start_tick = tick_count
        loop do
          instance_eval(&block)

          next unless tick_count > start_tick + 1000
          raise fail_message
        end
      end

      def next_tick
        @args.tick_count += 1
      end
    end

    module Colliders
      def initialize(args)
        super

        @args.state.colliders = [
          { collider: { x: -1000, y: -5, w: 2000, h: 5 } }
        ]
      end

      def collider_at(x:, y:, w:, h:)
        @args.state.colliders << { collider: { x: x, y: y, w: w, h: h } }
      end
    end
  end

  class PlayerDSL < DSL::Base
    include DSL::Colliders

    attr_reader :player, :last_input_actions

    def initialize(args)
      super

      @player = Player.build
      @initial_attributes = nil
    end

    def with(initial_attributes)
      @initial_attributes = initial_attributes
      @initial_attributes.each do |attribute, value|
        player[attribute] = value.dup
      end
    end

    def input(actions)
      @last_input_actions = actions
      @args.state.input_actions = actions

      Player.update!(@player, @args.state)

      next_tick
    end

    def no_input
      input({})
    end

    def player_description
      "player with #{@initial_attributes}"
    end
  end

  class CameraDSL < DSL::Base
    attr_reader :player, :camera

    def initialize(args)
      super

      @player = Player.build
      @camera = Camera.build
      Camera.follow_player! @camera, @player, immediately: true
    end

    def camera_position(x:, y:)
      @camera[:position] = { x: x, y: y }
    end

    def update_camera
      Camera.follow_player! @camera, @player
    end
  end
end
