def test_animations_integration_test(_args, assert)
  animation = Animations.build(
    w: 48, h: 48, tile_w: 48, tile_h: 48, path: 'resources/character.png',
    frames: [
      { tile_x: 0, tile_y: 0, duration: 3 },
      { tile_x: 48, tile_y: 48, duration: 3 }
    ]
  )
  primitive = { x: 100, y: 100 }
  first_frame = {
    x: 100, y: 100,
    w: 48, h: 48,
    tile_x: 0, tile_y: 0, tile_w: 48, tile_h: 48,
    path: 'resources/character.png'
  }
  second_frame = {
    x: 100, y: 100,
    w: 48, h: 48,
    tile_x: 48, tile_y: 48, tile_w: 48, tile_h: 48,
    path: 'resources/character.png'
  }

  animation_state = Animations.start! primitive, animation: animation
  assert.equal! primitive, first_frame

  2.times do
    Animations.next_tick animation_state
    Animations.apply! primitive, animation_state: animation_state

    assert.equal! primitive, first_frame
  end

  3.times do
    Animations.next_tick animation_state
    Animations.apply! primitive, animation_state: animation_state

    assert.equal! primitive, second_frame
  end

  Animations.next_tick animation_state
  Animations.apply! primitive, animation_state: animation_state

  assert.equal! primitive, first_frame
end

def test_animations_integration_test_no_repeat(_args, assert)
  animation = Animations.build(
    w: 48, h: 48, tile_w: 48, tile_h: 48, path: 'resources/character.png',
    frames: [
      { tile_x: 0, tile_y: 0, duration: 3 },
      { tile_x: 48, tile_y: 48, duration: 3 }
    ]
  )
  primitive = { x: 100, y: 100 }
  first_frame = {
    x: 100, y: 100,
    w: 48, h: 48,
    tile_x: 0, tile_y: 0, tile_w: 48, tile_h: 48,
    path: 'resources/character.png'
  }
  second_frame = {
    x: 100, y: 100,
    w: 48, h: 48,
    tile_x: 48, tile_y: 48, tile_w: 48, tile_h: 48,
    path: 'resources/character.png'
  }

  animation_state = Animations.start! primitive, animation: animation, repeat: false
  assert.equal! primitive, first_frame

  2.times do
    Animations.next_tick animation_state
    Animations.apply! primitive, animation_state: animation_state

    assert.equal! primitive, first_frame
  end

  3.times do
    Animations.next_tick animation_state
    Animations.apply! primitive, animation_state: animation_state

    assert.equal! primitive, second_frame
  end

  Animations.next_tick animation_state
  Animations.apply! primitive, animation_state: animation_state

  assert.equal! primitive, second_frame
end

def test_animations_flipped_horizontally(_args, assert)
  animation = AnimationsTests.an_animation
  flipped_animation = Animations.flipped_horizontally animation

  sprite1 = {}
  sprite2 = {}
  Animations.start! sprite1, animation: animation
  Animations.start! sprite2, animation: flipped_animation

  assert.equal! sprite2.flip_horizontally, !sprite1.flip_horizontally
end

def test_animations_finished_repeating_animation(_args, assert)
  animation = AnimationsTests.an_animation(length: 3)

  animation_state = Animations.start!({}, animation: animation)

  assert.false! Animations.finished? animation_state

  3.times do
    Animations.next_tick animation_state

    assert.false! Animations.finished? animation_state
  end
end

def test_animations_finished_one_time_animation(_args, assert)
  animation = AnimationsTests.an_animation(length: 3)

  animation_state = Animations.start!({}, animation: animation, repeat: false)

  assert.false! Animations.finished? animation_state

  2.times do
    Animations.next_tick animation_state

    assert.false! Animations.finished? animation_state
  end

  Animations.next_tick animation_state

  assert.true! Animations.finished? animation_state
end

module AnimationsTests
  class << self
    def an_animation(length: 6)
      Animations.build(
        w: 48, h: 48, tile_w: 48, tile_h: 48, path: 'resources/character.png',
        frames: [
          { tile_x: 0, tile_y: 0, duration: length }
        ]
      )
    end
  end
end
