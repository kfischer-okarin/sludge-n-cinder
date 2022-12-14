require 'tests/test_helpers.rb'

def test_slime_should_be_hurt_when_close_to_a_fire_particle(args, assert)
  SlimeTests.test(args) do
    with position: { x: 0, y: 0 }

    fire_particle position: { x: 7, y: 2 }

    update

    assert.equal! slime[:health][:ticks_since_hurt],
                  0,
                  "Expected #{slime_description} to be hurt when close to a fire particle " \
                  "but it wasn't"
  end
end

def test_slime_should_have_no_y_velocity_while_on_the_floor(args, assert)
  SlimeTests.test(args) do
    with state: :move, velocity: { x: 0, y: 0 }

    10.times do
      update

      assert.equal! slime[:velocity][:y],
                    0,
                    "Expected #{slime_description} to have no y velocity while on the floor " \
                    "but it had #{slime[:velocity][:y]}"
    end
  end
end

def test_slime_should_not_be_hurt_right_after_being_hurt(args, assert)
  SlimeTests.test(args) do
    with position: { x: 0, y: 0 }

    fire_particle position: { x: 7, y: 2 }
    update

    update

    assert.true! slime[:health][:ticks_since_hurt] > 0,
                  "Expected #{slime_description} not be hurt twice in a row " \
                  'but it was'
  end
end

def test_slime_should_lose_hp_when_being_hurt(args, assert)
  SlimeTests.test(args) do
    with position: { x: 0, y: 0 }

    fire_particle position: { x: 7, y: 2 }

    hp_before = slime[:health][:current]

    update

    assert.equal! slime[:health][:current],
                  hp_before - 1,
                  "Expected #{slime_description} to have lost hp " \
                  "but it didn't"
  end
end

def test_slime_should_prepare_attack_when_hurt(args, assert)
  SlimeTests.test(args) do
    with position: { x: 0, y: 0 }

    fire_particle position: { x: 7, y: 2 }

    update

    assert.equal! slime[:state],
                  :prepare_attack,
                  "Expected #{slime_description} to have state :prepare_attack " \
                  "but it had #{slime[:state]}"
  end
end

def test_slime_should_fly_towards_player_after_preparing_to_attack(args, assert)
  [
    { player_position: { x: -15, y: 0 }, face_direction: :left },
    { player_position: { x: 15, y: 0 }, face_direction: :right }
  ].each do |test_case|
    SlimeTests.test(args) do
      with state: :prepare_attack, position: { x: 0, y: 0 }

      player_position = test_case[:player_position]
      player_with position: player_position

      safe_loop "Expected #{slime_description} to start flying but it wasn't" do
        update

        break if slime[:state] == :flying
      end

      distance_before = (player_position[:x] - slime[:position][:x]).abs

      5.times { update }

      assert.true! (player_position[:x] - slime[:position][:x]).abs < distance_before,
                    "Expected #{slime_description} to fly towards the player " \
                    "at #{player_position} but it didn't. Its position was " \
                    "#{slime[:position]}"
      assert.equal! slime[:face_direction],
                    test_case[:face_direction],
                    "Expected #{slime_description} to have face direction " \
                    "at #{test_case[:face_direction]} but it didn't. It was " \
                    "#{slime[:face_direction]}"
    end
  end
end

def test_slime_should_not_be_affected_by_gravity_when_flying(args, assert)
  [
    { target: { position: { x: 100, y: 0 } } },
    { target: { position: { x: -100, y: 0 } } }
  ].each do |test_case|
    SlimeTests.test(args) do
      with position: { x: 0, y: 15 }

      Slime.fly_towards slime, test_case[:target]

      5.times { update }

      assert.equal! slime[:position][:y],
                    15,
                    "Expected #{slime_description} to have not been affected by gravity " \
                    "but its position was #{slime[:position]}"
    end
  end
end

def test_slime_should_not_slow_down_while_flying(args, assert)
  [
    { target: { position: { x: 100, y: 0 } } },
    { target: { position: { x: -100, y: 0 } } }
  ].each do |test_case|
    SlimeTests.test(args) do
      Slime.fly_towards slime, test_case[:target]

      x_velocity_before = slime[:velocity][:x]

      5.times { update }

      assert.equal! slime[:velocity][:x],
                    x_velocity_before,
                    "Expected #{slime_description} to have not slowed down " \
                    "while flying but it did"
    end
  end
end

def test_slime_should_eventually_stop_flying(args, assert)
  [
    { target: { position: { x: 100, y: 0 } } },
    { target: { position: { x: -100, y: 0 } } }
  ].each do |test_case|
    SlimeTests.test(args) do
      Slime.fly_towards slime, test_case[:target]

      safe_loop "Expected #{slime_description} to stop flying but never did" do
        update

        break if slime[:state] != :flying
      end

      assert.ok!
    end
  end
end

def test_slime_should_bounce_away_when_flying_into_collider_to_the_right(args, assert)
  SlimeTests.test(args) do
    collider_at x: 50, y: 0, w: 10, h: 30

    Slime.fly_towards slime, { position: { x: 100, y: 0 } }

    safe_loop "Expected #{slime_description} to bounce to the left but it never did" do
      update

      break if slime[:velocity][:x].negative?
    end

    assert.ok!
  end
end

def test_slime_should_bounce_away_when_flying_into_collider_to_the_left(args, assert)
  SlimeTests.test(args) do
    collider_at x: -50, y: 0, w: 10, h: 30

    Slime.fly_towards slime, { position: { x: -100, y: 0 } }

    safe_loop "Expected #{slime_description} to bounce to the right but it never did" do
      update

      break if slime[:velocity][:x].positive?
    end

    assert.ok!
  end
end

def test_slime_should_not_sink_when_stopping_flying(args, assert)
  [
    { target: { position: { x: 100, y: 0 } } },
    { target: { position: { x: -100, y: 0 } } }
  ].each do |test_case|
    SlimeTests.test(args) do
      Slime.fly_towards slime, test_case[:target]

      y_before = slime[:position][:y]

      safe_loop "Expected #{slime_description} to stop flying but never did" do
        update

        break if slime[:state] != :flying
      end

      5.times { update }

      assert.equal! slime[:position][:y],
                    y_before,
                    "Expected #{slime_description} to not sink when stopping flying " \
                    "but it did. Its position was #{slime[:position]}"
    end
  end
end

def test_slime_should_not_be_hurt_when_close_to_a_smoke_particle(args, assert)
  SlimeTests.test(args) do
    with position: { x: 0, y: 0 }

    fire_particle position: { x: 7, y: 2 }, state: :smoke

    update

    assert.true! slime[:health][:ticks_since_hurt] != 0,
                 "Expected #{slime_description} not to be hurt when close to a smoke particle " \
                 'but it was'
  end
end

def test_slime_should_be_hurled_left_sideways_when_hurt_from_the_right(args, assert)
  SlimeTests.test(args) do
    with position: { x: 0, y: 0 }, face_direction: :right

    fire_particle position: { x: 7, y: 2 }, velocity: { x: -1, y: 0 }

    5.times { update }

    assert.true! slime[:position][:x] < 0,
                 "Expected #{slime_description} to be hurled left when hurt from the right " \
                 "but it's position was #{slime[:position]}"
  end
end

def test_slime_should_be_hurled_right_sideways_when_hurt_from_the_left(args, assert)
  SlimeTests.test(args) do
    with position: { x: 0, y: 0 }, face_direction: :left

    fire_particle position: { x: -7, y: 2 }, velocity: { x: 1, y: 0 }

    5.times { update }

    assert.true! slime[:position][:x] > 0,
                 "Expected #{slime_description} to be hurled right when hurt from the left " \
                 "but it's position was #{slime[:position]}"
  end
end

def test_slime_ticks_since_hurt_increase(args, assert)
  SlimeTests.test(args) do
    ticks_since_hurt_before = slime[:health][:ticks_since_hurt]

    update

    assert.equal! slime[:health][:ticks_since_hurt],
                  ticks_since_hurt_before + 1,
                  'Expected slime to increase ticks_since_hurt by 1'
  end
end

module SlimeTests
  class << self
    def test(args, &block)
      TestHelpers::SlimeDSL.new(args).instance_eval(&block)
    end
  end
end
