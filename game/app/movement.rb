module Movement
  class << self
    def apply!(entity, colliders)
      apply_gravity(entity)
      x_movement = move(entity, :x, colliders: colliders)
      y_movement = move(entity, :y, colliders: colliders)

      {
        collisions: x_movement[:collisions].merge(y_movement[:collisions]),
        position_change: {
          x: x_movement[:change],
          y: y_movement[:change]
        }
      }
    end

    private

    def apply_gravity(entity)
      entity[:movement][:y] += entity[:y_velocity]
      entity[:y_velocity] = [entity[:y_velocity] - GRAVITY, -MAX_FALL_VELOCITY].max
    end

    def move(entity, dimension, colliders:)
      abs_movement = entity[:movement][dimension].abs
      sign = entity[:movement][dimension].sign
      entity_at_next_position = {
        position: entity[:position].dup,
        collider_bounds: entity[:collider_bounds],
        collider: entity[:collider].dup
      }
      next_position = entity_at_next_position[:position]
      collided_with = nil

      while abs_movement >= 1
        abs_movement -= 1
        next_position[dimension] += sign
        update_collider entity_at_next_position
        collided_with = check_collision(entity_at_next_position, colliders)
        if collided_with
          next_position[dimension] -= sign
          update_collider entity_at_next_position
          abs_movement = 0
        end
      end

      change = next_position[dimension] - entity[:position][dimension]
      entity[:position] = next_position
      entity[:collider] = entity_at_next_position[:collider]
      entity[:movement][dimension] = abs_movement * sign

      collisions = {}
      collisions[direction(dimension, sign)] = collided_with if collided_with
      {
        collisions: collisions,
        change: change
      }
    end

    def update_collider(entity)
      position = entity[:position]
      collider_bounds = entity[:collider_bounds]
      collider = entity[:collider]
      collider[:x] = position[:x] + collider_bounds[:x]
      collider[:y] = position[:y] + collider_bounds[:y]
      collider[:w] = collider_bounds[:w]
      collider[:h] = collider_bounds[:h]
    end

    def check_collision(entity, colliders)
      colliders.find { |collider|
        entity[:collider].intersect_rect? collider[:collider]
      }
    end

    def direction(dimension, sign)
      case dimension
      when :x then sign == 1 ? :right : :left
      when :y then sign == 1 ? :up : :down
      end
    end
  end
end
