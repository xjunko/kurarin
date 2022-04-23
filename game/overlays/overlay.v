module overlays

import math

import library.gg

import game.skin
import game.cursor
import game.ruleset

import framework.math.time
import framework.math.vector
import framework.graphic.sprite

pub struct GameplayOverlay {
	pub mut:
		last_time f64
		combo     i64
		new_combo i64

		ruleset &ruleset.Ruleset
		cursor  &cursor.Cursor

		key_states [4]bool
		key_counters [4]int
		last_presses [4]f64
		keys_background &sprite.Sprite = voidptr(0)
		keys []&sprite.Sprite

		ctx &gg.Context
}

pub fn (mut overlay GameplayOverlay) update(_time f64) {
	for mut sprite in overlay.keys {
		sprite.update(_time)
	}

	// KEYs
	current_states := [overlay.cursor.left_button, overlay.cursor.right_button]!

	for i, state in current_states {
		if !overlay.key_states[i] && state {
			mut key := &overlay.keys[i]

			key.remove_transform_by_type(.scale_factor)
			key.add_transform(typ: .scale_factor, time: time.Time{_time, _time + 100.0}, before: [1.0], after: [0.8])

			overlay.last_presses[i] = _time + 100.0
		}

		if overlay.key_states[i] && !state {
			mut key := &overlay.keys[i]

			key.remove_transform_by_type(.scale_factor)
			key.add_transform(typ: .scale_factor, time: time.Time{math.max<f64>(_time, overlay.last_presses[i]), _time + 100.0}, before: [key.size.y / key.raw_size.y], after: [1.0])
		}

		overlay.key_states[i] = state
	}

	overlay.last_time = _time
}

pub fn (mut overlay GameplayOverlay) draw() {
	overlay.keys_background.draw(time: overlay.last_time, ctx: overlay.ctx)

	for mut sprite in overlay.keys {
		sprite.draw(time: overlay.last_time, ctx: overlay.ctx)
	}
}

pub fn new_gameplay_overlay(ruleset &ruleset.Ruleset, cursor &cursor.Cursor, ctx &gg.Context) &GameplayOverlay {
	mut overlay := &GameplayOverlay{
		ruleset: unsafe { ruleset },
		cursor: unsafe { cursor },
		ctx: unsafe { ctx }
	}

	overlay.keys_background = &sprite.Sprite{origin: vector.top_left, always_visible: true}
	overlay.keys_background.add_transform(typ: .move, time: time.Time{0.0, 0.0}, before: [1145.0, 720.0 / 2.0 + 10.0])
	overlay.keys_background.add_transform(typ: .angle, time: time.Time{0.0, 0.0}, before: [math.pi / 2.0])
	overlay.keys_background.add_transform(typ: .scale, time: time.Time{0.0, 0.0}, before: [1.05, 1.0])
	overlay.keys_background.textures << skin.get_texture("inputoverlay-background")
	overlay.keys_background.reset_size_based_on_texture()
	overlay.keys_background.reset_attributes_based_on_transforms()

	for i in 0 .. 4 {
		pos_y := 720.0 / 2.0 -  64.0 + (30.4 + f64(i) * 47.2) * 1.0
		
		mut key := &sprite.Sprite{}
		key.add_transform(typ: .move, time: time.Time{0.0, 0.0}, before: [1280.0 - 24.0 * 1.0, pos_y])
		key.textures << skin.get_texture("inputoverlay-key")
		key.always_visible = true
		key.reset_size_based_on_texture()
		key.reset_attributes_based_on_transforms()

		overlay.keys << key
	}

	return overlay
}