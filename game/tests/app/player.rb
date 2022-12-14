require 'tests/test_helpers.rb'

def test_player_start_running(args, assert)
  PlayerTests.test(args) do
    input move: :right

    assert.equal! player[:state], :run
  end
end

def test_player_stop_running(args, assert)
  PlayerTests.test(args) do
    with state: :run

    no_input

    assert.equal! player[:state], :idle
  end
end

def test_player_keep_idle(args, assert)
  PlayerTests.test(args) do
    no_input

    assert.equal! player[:state], :idle
  end
end

def test_player_keep_running(args, assert)
  %i[left right].each do |direction|
    PlayerTests.test(args) do
      with state: :run

      input move: direction

      assert.equal! player[:state], :run
    end
  end
end

def test_player_start_jumping_when_idle(args, assert)
  [
    { jump: true },
    { move: :right, jump: true },
    { move: :left, jump: true }
  ].each do |input_actions|
    PlayerTests.test(args) do
      input input_actions

      assert.equal! player[:state], :jump
    end
  end
end

def test_player_start_jumping_when_running(args, assert)
  PlayerTests.test(args) do
    with state: :run

    input jump: true

    assert.equal! player[:state], :jump
  end
end

def test_player_stop_jumping(args, assert)
  PlayerTests.test(args) do
    with state: :jump, position: { x: 0, y: 5 }

    safe_loop "Expected #{player_description} to become idle, but he didn't" do
      no_input

      break if player[:state] != :jump
    end

    assert.ok!
  end
end

def test_player_firing(args, assert)
  PlayerTests.test(args) do
    with firing: false

    input fire: true

    assert.true! player[:firing]
  end
end

def test_player_falling(args, assert)
  PlayerTests.test(args) do
    with state: :idle, position: { x: 0, y: 20 }

    collider_at x: -10, y: 15, w: 20, h: 5

    safe_loop "Expected #{player_description} to start falling, but he didn't" do
      y_before_tick = player[:position][:y]

      input move: :right

      break if player[:position][:y] < y_before_tick

      assert.equal! player[:state], :run
    end

    assert.equal! player[:state], :jump
  end
end

def test_player_face_direction(args, assert)
  %i[left right].each do |initial_face_direction|
    %i[left right].each do |move_direction|
      %i[idle run jump].each do |state|
        PlayerTests.test(args) do
          with state: state, face_direction: initial_face_direction

          input move: move_direction

          assert.equal! player[:face_direction],
                        move_direction,
                        "Expected #{last_input_actions} to change #{player_description} " \
                        "to have face_direction #{move_direction} but it was #{player[:face_direction]}"
        end
      end
    end
  end
end

def test_player_dont_change_face_direction_when_firing(args, assert)
  %i[left right].each do |initial_face_direction|
    %i[left right].each do |move_direction|
      %i[idle run jump].each do |state|
        PlayerTests.test(args) do
          with state: state, face_direction: initial_face_direction, firing: true

          input move: move_direction, fire: true

          assert.equal! player[:face_direction],
                        initial_face_direction,
                        "Expected #{last_input_actions} to not to change face direction of " \
                        "#{player_description} but it was changed to #{player[:face_direction]}"
        end
      end
    end
  end
end

def test_player_move_right(args, assert)
  %i[idle run jump].each do |state|
    PlayerTests.test(args) do
      with state: state, position: { x: 0, y: 0 }

      10.times { input move: :right }

      assert.true! player[:position][:x] > 0,
                   "Expected #{last_input_actions} to change #{player_description} " \
                   "to have a x position > 0 but it was #{player[:position]}"
    end
  end
end

def test_player_move_left(args, assert)
  %i[idle run jump].each do |state|
    PlayerTests.test(args) do
      with state: state, position: { x: 0, y: 0 }

      10.times { input move: :left }

      assert.true! player[:position][:x] < 0,
                   "Expected #{last_input_actions} to change #{player_description} " \
                   "to have a x position < 0 but it was #{player[:position]}"
    end
  end
end

def test_player_walk_backwards_while_firing_right(args, assert)
  %i[idle run jump].each do |state|
    PlayerTests.test(args) do
      with state: state, position: { x: 0, y: 0 }, face_direction: :right, firing: true

      10.times { input move: :left, fire: true }

      assert.true! player[:position][:x] < 0,
                   "Expected #{last_input_actions} to change #{player_description} " \
                   "to have a x position < 0 but it was #{player[:position]}"
    end
  end
end

def test_player_walk_backwards_while_firing_left(args, assert)
  %i[idle run jump].each do |state|
    PlayerTests.test(args) do
      with state: state, position: { x: 0, y: 0 }, face_direction: :left, firing: true

      10.times { input move: :right, fire: true }

      assert.true! player[:position][:x] > 0,
                   "Expected #{last_input_actions} to change #{player_description} " \
                   "to have a x position > 0 but it was #{player[:position]}"
    end
  end
end

def test_player_move_slower_while_firing(args, assert)
  distance_while_firing = nil
  distance_while_not_firing = nil

  PlayerTests.test(args) do
    with firing: true

    x_before = player[:position][:x]

    10.times { input move: :right, fire: true }

    distance_while_firing = player[:position][:x] - x_before
  end

  PlayerTests.test(args) do
    x_before = player[:position][:x]

    10.times { input move: :right }

    distance_while_not_firing = player[:position][:x] - x_before
  end

  assert.true! distance_while_firing < distance_while_not_firing,
               "Expected player to move slower while firing but he didn't " \
               "(while firing: #{distance_while_firing}, while not firing: #{distance_while_not_firing})"
end

def test_player_movement_stop_moving(args, assert)
  %i[run jump].each do |state|
    PlayerTests.test(args) do
      with state: state
      input move: :right
      x_before_stopping = player[:position][:x]

      no_input

      assert.equal! player[:position][:x],
                    x_before_stopping,
                    "Expected #{last_input_actions} to make #{player_description} " \
                    "stop moving x position changed from #{x_before_stopping} to #{player[:position][:x]}"
    end
  end
end

def test_player_should_move_up_after_jumping(args, assert)
  %i[idle run].each do |state|
    PlayerTests.test(args) do
      with state: state, position: { x: 0, y: 0 }

      input jump: true

      assert.true! player[:position][:y] > 0,
                   "Expected #{last_input_actions} to move #{player_description} " \
                   "upwards movement but it was #{player[:position]}"
    end
  end
end

def test_player_should_move_up_several_ticks_after_jumping(args, assert)
  %i[idle run].each do |state|
    PlayerTests.test(args) do
      with state: state
      input jump: true

      2.times do
        y_before_tick = player[:position][:y]

        no_input

        assert.true! player[:position][:y] > y_before_tick,
                     "Expected #{last_input_actions} to move #{player_description} " \
                     "upwards for more than #{tick_count} ticks " \
                     "but y position change was: #{player[:position][:y] - y_before_tick}"
      end
    end
  end
end

def test_player_should_eventually_move_down_after_jumping(args, assert)
  %i[idle run].each do |state|
    PlayerTests.test(args) do
      with state: state
      input jump: true

      safe_loop "Expected #{player_description} to eventually fall down after jumping, but he didn't" do
        y_before_tick = player[:position][:y]

        no_input

        break if player[:position][:y] < y_before_tick
      end
    end
  end

  assert.ok!
end

def test_player_should_only_fall_until_the_floor(args, assert)
  %i[idle run].each do |state|
    PlayerTests.test(args) do
      with state: state
      input jump: true

      safe_loop "Expected #{player_description} to reach the ground, but he didn't" do
        y_before_tick = player[:position][:y]

        no_input

        break if player[:position][:y].zero? && y_before_tick == player[:position][:y]

        next unless player[:position][:y] < 0

        raise "Expected #{player_description} to reach the ground, but he fell through"
      end
    end
  end

  assert.ok!
end

def test_player_should_not_be_able_to_jump_again_without_releasing_the_jump_button(args, assert)
  %i[idle run].each do |state|
    PlayerTests.test(args) do
      with state: state
      input jump: true
      no_input # Releasing jump button mid-air doesn't count as releasing

      safe_loop "Expected #{player_description} to land, but he didn't" do
        input jump: true

        break if player[:state] == :idle
      end

      input jump: true

      assert.equal! player[:state],
                    :idle,
                    'Expected player not to be able to jump again ' \
                    'without releasing the jump button but he could'

      no_input
      input jump: true

      assert.equal! player[:state],
                    :jump,
                    'Expected player to be able to jump again ' \
                    "after releasing the jump button but he couldn't"
    end
  end

  assert.ok!
end

def test_player_should_jump_higher_when_holding_the_jump_button(args, assert)
  %i[idle run].each do |state|
    max_height_without_holding_the_button = 0
    max_height_with_holding_the_button = 0

    PlayerTests.test(args) do
      with state: state
      input jump: true

      safe_loop "Expected #{player_description} to reach the ground, but he didn't" do
        max_height_without_holding_the_button = [max_height_without_holding_the_button, player[:position][:y]].max

        no_input

        break if player[:state] == :idle
      end
    end

    PlayerTests.test(args) do
      with state: state
      input jump: true

      safe_loop "Expected #{player_description} to reach the ground, but he didn't" do
        max_height_with_holding_the_button = [max_height_with_holding_the_button, player[:position][:y]].max

        input jump: true

        break if player[:state] == :idle
      end
    end

    assert.true! max_height_with_holding_the_button > max_height_without_holding_the_button,
                 'Expected player to jump higher when holding the jump button, ' \
                 "but with holding (y position: #{max_height_with_holding_the_button}) " \
                 "was not higher than without holding (y position: #{max_height_without_holding_the_button})"
  end
end

def test_player_should_not_fall_slower_when_holding_the_jump_button(args, assert)
  %i[idle run].each do |state|
    y_after_holding_button_when_falling = 0
    y_after_just_falling = 0

    PlayerTests.test(args) do
      with state: state
      input jump: true

      safe_loop "Expected #{player_description} to start falling, but he didn't" do
        y_before_tick = player[:position][:y]

        input jump: true

        break if player[:position][:y] < y_before_tick
      end

      10.times { input jump: true }

      y_after_holding_button_when_falling = player[:position][:y]
    end

    PlayerTests.test(args) do
      with state: state
      input jump: true

      safe_loop "Expected #{player_description} to start falling, but he didn't" do
        y_before_tick = player[:position][:y]

        input jump: true

        break if player[:position][:y] < y_before_tick
      end

      10.times { no_input }

      y_after_just_falling = player[:position][:y]
    end

    assert.equal! y_after_holding_button_when_falling, y_after_just_falling,
                 "Expected player to not fall slower when holding the jump button, " \
                 "but with holding (y position: #{y_after_holding_button_when_falling}) " \
                 "was higher than without holding (y position: #{y_after_just_falling})"
  end
end

def test_player_should_have_maximum_falling_speed(args, assert)
  PlayerTests.test(args) do
    with state: :jump, position: { x: 0, y: 50 }
    last_y_velocity = player[:velocity][:y]

    safe_loop "Expected #{player_description} to reach maximum speed, but he didn't" do
      no_input

      y_velocity = player[:velocity][:y]

      break if y_velocity == last_y_velocity

      raise 'Player reached floor before reaching maximum speed' if player[:state] == :idle

      last_y_velocity = y_velocity
    end

    assert.ok!
  end
end

def test_player_should_fall_until_collider(args, assert)
  PlayerTests.test(args) do
    with state: :jump, position: { x: 0, y: 50 }

    collider_at x: -10, y: 20, w: 20, h: 5

    safe_loop "Expected #{player_description} to stop falling, but he didn't" do
      no_input

      break if player[:state] == :idle
    end

    assert.equal! player[:position][:y],
                  25,
                  "Expected #{player_description} to stop falling at the collider " \
                  "but his y position was #{player[:position][:y]}"
  end
end

def test_player_should_not_walk_through_colliders(args, assert)
  PlayerTests.test(args) do
    with state: :idle, position: { x: 0, y: 0 }

    collider_at x: 20, y: 0, w: 10, h: 10

    safe_loop "Expected #{player_description} to stop walking, but he didn't" do
      x_before_tick = player[:position][:x]

      input move: :right

      break if player[:position][:x] == x_before_tick
    end

    assert.true! player[:position][:x] < 20,
                 "Expected #{player_description} to not be able to walk through the " \
                 "collider #{args.state.colliders.last} " \
                 "but he could"
  end
end

def test_player_should_not_be_able_to_jump_through_colliders_from_below(args, assert)
  PlayerTests.test(args) do
    with state: :idle, position: { x: 20, y: 0 }

    collider_at x: 10, y: 30, w: 20, h: 10

    safe_loop "Expected #{player_description} to land, but he didn't" do
      input jump: true

      break if player[:position][:y].zero?

      next unless player[:collider].top > 30

      raise "Player passed through the collider: Current position #{player[:position]}"
    end

    assert.ok!
  end
end

def test_player_should_immediately_fall_when_hitting_colliders_from_below(args, assert)
  PlayerTests.test(args) do
    with state: :idle, position: { x: 20, y: 0 }

    collider_at x: 10, y: 30, w: 20, h: 10

    safe_loop "Expected #{player_description} to hit the collider, but he didn't" do
      input jump: true

      break if player[:collider].top == 30
    end

    no_input

    assert.true! player[:velocity][:y].negative?,
                  "Expected #{player_description} to fall immediately after hitting the collider, " \
                  "but his y position was #{player[:position][:y]}"
  end
end

def test_player_should_be_hurt_when_running_into_the_slime(args, assert)
  [
    { position: { x: 0, y: 0 }, move: :right, slime_position: { x: 20, y: 0 } },
    { position: { x: 0, y: 0 }, move: :left, slime_position: { x: -20, y: 0 } }
  ].each do |test_case|
    PlayerTests.test(args) do
      with position: test_case[:position]

      slime_is at: test_case[:slime_position]

      safe_loop "Expected #{player_description} to be hurt, but he wasn't" do
        input move: test_case[:move]

        break if player[:health][:ticks_since_hurt].zero?
      end

      assert.ok!
    end
  end
end

def test_player_should_lose_hp_when_running_into_the_slime(args, assert)
  [
    { position: { x: 0, y: 0 }, move: :right, slime_position: { x: 20, y: 0 } },
    { position: { x: 0, y: 0 }, move: :left, slime_position: { x: -20, y: 0 } }
  ].each do |test_case|
    PlayerTests.test(args) do
      with position: test_case[:position]

      slime_is at: test_case[:slime_position]

      current_hp_before = player[:health][:current]

      safe_loop "Expected #{player_description} to be hurt, but he wasn't" do
        input move: test_case[:move]

        break if player[:health][:ticks_since_hurt].zero?
      end

      assert.equal! player[:health][:current],
                    current_hp_before - 1,
                    "Expected #{player_description} to lose 1 hp " \
                    "when running to the #{test_case[:move]} into the slime"
    end
  end
end

def test_player_should_not_be_hurt_right_after_being_hurt(args, assert)
  [
    { position: { x: 0, y: 0 }, move: :right, slime_position: { x: 20, y: 0 } },
    { position: { x: 0, y: 0 }, move: :left, slime_position: { x: -20, y: 0 } }
  ].each do |test_case|
    PlayerTests.test(args) do
      with position: test_case[:position]

      slime_is at: test_case[:slime_position]

      safe_loop "Expected #{player_description} to be hurt, but he wasn't" do
        input move: test_case[:move]

        break if player[:health][:ticks_since_hurt].zero?
      end

      no_input

      assert.equal! player[:health][:ticks_since_hurt],
                    1,
                    "Expected #{player_description} to not be hurt twice in a row" \
                    "when running to the #{test_case[:move]} into the slime"
    end
  end
end

def test_player_should_be_hurled_left_up_after_running_right_into_the_slime(args, assert)
  PlayerTests.test(args) do
    with position: { x: 0, y: 0 }

    slime_is at: { x: 20, y: 0 }

    safe_loop "Expected #{player_description} to be hurt, but he wasn't" do
      input move: :right

      break if player[:health][:ticks_since_hurt].zero?
    end

    position_before = player[:position].dup

    5.times { no_input }

    assert.true! player[:position][:x] < position_before[:x] && player[:position][:y] > position_before[:y],
                 "Expected #{player_description} to be hurled left up " \
                 'after running right into the slime but his position after 5 ticks ' \
                 "was #{player[:position]}"
    assert.equal! player[:state],
                 :jump,
                 "Expected #{player_description} to be falling " \
                 'after running right into the slime but his position after 5 ticks ' \
                 "but he was #{player[:state]}"
  end
end

def test_player_should_be_hurled_right_up_after_running_left_into_the_slime(args, assert)
  PlayerTests.test(args) do
    with position: { x: 0, y: 0 }

    slime_is at: { x: -20, y: 0 }

    safe_loop "Expected #{player_description} to be hurt, but he wasn't" do
      input move: :left

      break if player[:health][:ticks_since_hurt].zero?
    end

    position_before = player[:position].dup

    5.times { no_input }

    assert.true! player[:position][:x] > position_before[:x] && player[:position][:y] > position_before[:y],
                 "Expected #{player_description} to be hurled right up " \
                 'after running left into the slime but his position after 5 ticks ' \
                 "was #{player[:position]}"
    assert.equal! player[:state],
                  :jump,
                  "Expected #{player_description} to be falling " \
                  'after running left into the slime but his position after 5 ticks ' \
                  "but he was #{player[:state]}"
  end
end

def test_player_ticks_since_hurt_increase(args, assert)
  PlayerTests.test(args) do
    ticks_since_hurt_before = player[:health][:ticks_since_hurt]

    no_input

    assert.equal! player[:health][:ticks_since_hurt],
                  ticks_since_hurt_before + 1,
                  'Expected player to increase ticks_since_hurt by 1'
  end
end

module PlayerTests
  class << self
    def test(args, &block)
      TestHelpers::PlayerDSL.new(args).instance_eval(&block)
    end
  end
end
