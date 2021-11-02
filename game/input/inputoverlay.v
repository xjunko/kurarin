module input

import time
import lib.gg
import framework.graphic.sprite
import framework.math.time

import game.math.resolution

pub struct InputOverlay {
	pub mut:
		ctx       &gg.Context
		keys_down []gg.KeyCode
		background &sprite.Sprite = &sprite.Sprite{}
		sprites   map[gg.KeyCode]&sprite.Sprite
}

pub fn (mut input_overlay InputOverlay) draw(time f64) {
	input_overlay.background.draw_and_update(ctx: input_overlay.ctx, time: time)
	for _, mut sprite in input_overlay.sprites {
		sprite.draw_and_update(ctx: input_overlay.ctx, time: time)
	}
}

pub fn (mut input_overlay InputOverlay) initialize_sprite_component() {
	input_overlay.background = &sprite.Sprite{
		textures: [gg.get_texture_from_skin('inputoverlay-background')]
		always_visible: true,
		angle: -90
	}
	input_overlay.background.add_transform(typ: .move, time: time.Time{0, 0}, before: [f64(resolution.global.width - input_overlay.background.image().width / 2 + 32), resolution.global.height / 2])
	input_overlay.background.reset_attributes_based_on_transforms()
	input_overlay.background.reset_image_size()

	for i, key in [gg.KeyCode.z, gg.KeyCode.x] {
		input_overlay.sprites[key] = &sprite.Sprite{
			textures: [gg.get_texture_from_skin('inputoverlay-key')],
			always_visible: true
		}

		input_overlay.sprites[key].add_transform(typ: .move, time: time.Time{0, 0}, before: [f64(resolution.global.width - input_overlay.background.image().width / 2 + 85), f64(((resolution.global.height - 163) / 2) + i * 45)])
		input_overlay.sprites[key].reset_attributes_based_on_transforms()
		input_overlay.sprites[key].reset_image_size()
	}
}

pub fn (mut input_overlay InputOverlay) click(key gg.KeyCode, time_ f64) bool {
	if key !in input_overlay.keys_down {
		input_overlay.keys_down << key

		input_overlay.sprites[key].remove_all_transform_with_type(.scale_factor)
		input_overlay.sprites[key].add_transform(typ: .scale_factor, time: time.Time{time_, time_+64}, before: [1.0], after: [0.8])
		
		// println('clicked x')
		return true
	}

	return true
}

pub fn (mut input_overlay InputOverlay) release(released gg.KeyCode, time_ f64) bool {
	if released in input_overlay.keys_down {
			input_overlay.keys_down = input_overlay.keys_down.filter(it == released)

			input_overlay.sprites[released].remove_all_transform_with_type(.scale_factor)
			input_overlay.sprites[released].add_transform(typ: .scale_factor, time: time.Time{time_, time_+64}, before: [0.8], after: [1.0])
			
			// println('released x')
			// println(input_overlay.keys_down)
			// println(released)
			return true
	}
	return true
}