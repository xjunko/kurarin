module overlays

import math

import gx
import library.gg

import game.x
import game.skin
import game.cursor
import game.ruleset
import game.settings

import framework.math.time
import framework.math.vector
import framework.graphic.sprite

import gameplay

const (
	g_overlay_hack = &GameplayOverlay{ctx: 0, ruleset: 0, cursor: 0, hitresult: 0, combo_counter: 0}
)

pub struct GameplayOverlay {
	pub mut:
		last_time f64
		combo     i64
		new_combo i64

		score        i64
		score_smooth i64
		score_font   &sprite.NumberSprite = voidptr(0)

		ruleset &ruleset.Ruleset
		cursor  &cursor.Cursor

		key_states [4]bool
		key_counters [4]int
		last_presses [4]f64
		keys_background &sprite.Sprite = voidptr(0)
		keys []&sprite.Sprite

		ctx &gg.Context
		
		// 
		hitresult &gameplay.HitResults
		combo_counter &gameplay.ComboCounter
}

pub fn (mut overlay GameplayOverlay) update(_time f64) {
	overlay.combo_counter.update(_time)
	overlay.hitresult.update(_time)

	for mut sprite in overlay.keys {
		sprite.update(_time)
	}

	// KEYs
	current_states := [overlay.cursor.left_button, overlay.cursor.right_button]!

	for i, state in current_states {
		mut color := [255.0, 222.0, 0.0]

		if i > 1 {
			color = [248.0, 0.0, 158.0]
		}

		if !overlay.key_states[i] && state {
			mut key := &overlay.keys[i]

			key.remove_transform_by_type(.scale_factor)
			key.add_transform(typ: .scale_factor, time: time.Time{_time, _time + 100.0}, before: [1.0], after: [0.8])
			key.add_transform(typ: .color, time: time.Time{_time, _time + 100.0}, before: [255.0, 255.0, 255.0], after: color)

			overlay.key_counters[i]++
			overlay.last_presses[i] = _time + 100.0
		}

		if overlay.key_states[i] && !state {
			mut key := &overlay.keys[i]

			key.remove_transform_by_type(.scale_factor)
			key.add_transform(typ: .scale_factor, time: time.Time{math.max<f64>(_time, overlay.last_presses[i]), _time + 100.0}, before: [key.size.y / key.raw_size.y], after: [1.0])
			key.add_transform(typ: .color, time: time.Time{_time, _time + 100.0}, before: color, after: [255.0, 255.0, 255.0])
		}

		overlay.key_states[i] = state
	}

	overlay.score_font.update(_time)
	overlay.last_time = _time
}

pub fn (mut overlay GameplayOverlay) draw() {
	overlay.hitresult.draw()
	overlay.keys_background.draw(time: overlay.last_time, ctx: overlay.ctx)

	for i, mut sprite in overlay.keys {
		// Sprite
		sprite.draw(time: overlay.last_time, ctx: overlay.ctx)
		// Text
		relative_size := ((sprite.size.y * 8.0) / 16.0) * x.resolution.ui_camera.scale
		pos_x := settings.global.window.width - 24.0 * 1.0
		pos_y := settings.global.window.height / 2.0 - 64 + ((18.0 + (18 * (1.0 - (relative_size / 23.0)))) + f64(i) * 47.2) * x.resolution.ui_camera.scale
		overlay.ctx.draw_text(int(pos_x), int(pos_y), overlay.key_counters[i].str(), gx.TextCfg{color: gx.white, align: .center, size: int(relative_size)})
	}

	overlay.combo_counter.draw(ctx: overlay.ctx, scale: x.resolution.ui_camera.scale)

	// Score
	overlay.score_smooth = i64(f64(overlay.score) * 0.5 + f64(overlay.score_smooth) - f64(overlay.score_smooth) * 0.5)
	overlay.score_font.draw_number("${overlay.score_smooth:08d}", vector.Vector2{settings.global.window.width - 5 - (8 * (overlay.score_font.size.x * x.resolution.ui_camera.scale)), 0}, vector.top_left, ctx: overlay.ctx, time: overlay.last_time, scale: x.resolution.ui_camera.scale)
}

pub fn new_gameplay_overlay(ruleset &ruleset.Ruleset, cursor &cursor.Cursor, ctx &gg.Context) &GameplayOverlay {
	mut hitresult := gameplay.make_hit_result(ctx, ruleset.beatmap.difficulty.Difficulty)
	mut counter := gameplay.make_combo_counter()
	mut score_font := sprite.make_number_font("score")

	mut overlay := &GameplayOverlay{
		ruleset: unsafe { ruleset },
		cursor: unsafe { cursor },
		ctx: unsafe { ctx },
		hitresult: hitresult,
		combo_counter: counter,
		score_font: score_font
	}

	overlay.keys_background = &sprite.Sprite{origin: vector.top_left, always_visible: true}
	overlay.keys_background.add_transform(typ: .move, time: time.Time{0.0, 0.0}, before: [settings.global.window.width, settings.global.window.height / 2.0 - 64.0])
	overlay.keys_background.add_transform(typ: .angle, time: time.Time{0.0, 0.0}, before: [math.pi / 2.0])
	overlay.keys_background.add_transform(typ: .scale, time: time.Time{0.0, 0.0}, before: [1.05, 1.0])
	overlay.keys_background.textures << skin.get_texture("inputoverlay-background")
	overlay.keys_background.reset_size_based_on_texture(factor: x.resolution.ui_camera.scale)
	overlay.keys_background.reset_attributes_based_on_transforms()

	for i in 0 .. 4 {
		pos_y := settings.global.window.height / 2.0 -  64.0 + (30.4 + f64(i) * 47.2) * x.resolution.ui_camera.scale
		
		mut key := &sprite.Sprite{}
		key.add_transform(typ: .move, time: time.Time{0.0, 0.0}, before: [settings.global.window.width - 24.0 * 1.0, pos_y])
		key.textures << skin.get_texture("inputoverlay-key")
		key.always_visible = true
		key.reset_size_based_on_texture(factor: x.resolution.ui_camera.scale)
		key.reset_attributes_based_on_transforms()

		overlay.keys << key
	}

	overlay.ruleset.set_listener(hit_received)

	// HACK: bruh
	unsafe { g_overlay_hack = overlay  }

	return overlay
}


// Some hack
pub fn hit_received(time f64, number i64, position vector.Vector2, result ruleset.HitResult, combo ruleset.ComboResult, score i64) {
	mut g_overlay := unsafe { g_overlay_hack }
	g_overlay.score = score
	g_overlay.hitresult.add_result(time, result, position)

	if combo == .increase {
		g_overlay.combo_counter.increase()
	} else if combo == .reset {
		g_overlay.combo_counter.reset()
	}
}