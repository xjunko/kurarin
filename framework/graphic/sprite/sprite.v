module sprite

import library.gg
import gx
import math

import framework.logging
import framework.math.time
import framework.math.transform
import framework.math.vector

pub struct Sprite {
	pub mut:
		time       time.Time
		transforms []transform.Transform
		textures   []gg.Image
		texture_i  int

		// Attrs
		additive       bool
		always_visible bool
		origin    vector.Vector2 = vector.centre
		position  vector.Vector2
		size      vector.Vector2
		raw_size  vector.Vector2
		color     gx.Color = gx.white
		angle     f64
}


// Transform FNs
pub fn (mut sprite Sprite) apply_event(t transform.Transform, time f64) {
	match t.typ {
		.move {
			pos := t.as_vector(time)
			sprite.position.x = pos.x
			sprite.position.y = pos.y
			// logging.info(pos)
		}

		.move_x {
			sprite.position.x = t.as_one(time)
		}
		
		.move_y {
			sprite.position.y = t.as_one(time) 
		}

		.angle {
			sprite.angle = (t.as_one(time) * 180 / math.pi) * -1.0
		}

		.color {
			pos := t.as_three(time)
			sprite.color.r = byte(pos[0])
			sprite.color.g = byte(pos[1])
			sprite.color.b = byte(pos[2])
		}
		
		.fade {
			sprite.color.a = byte(t.as_one(time))
		}

		.scale {
			v := t.as_vector(time)
			sprite.size.x = sprite.raw_size.x * v.x
			sprite.size.y = sprite.raw_size.y * v.y
		}

		.scale_factor {
			factor := t.as_one(time)
			sprite.size.x = sprite.raw_size.x * factor
			sprite.size.y = sprite.raw_size.y * factor
		}

		// else {}
	}
}

pub fn (mut sprite Sprite) remove_transform_by_type(t transform.TransformType) {
	for mut transform in sprite.transforms {
		if transform.typ == t {
			sprite.transforms.delete(sprite.transforms.index(transform))
		}
	}
}

pub fn (mut sprite Sprite) reset_transform() {
	sprite.transforms = []transform.Transform{} // TODO: better way to clear transforms 
}

pub fn (mut sprite Sprite) add_transform(_t transform.Transform) {
	mut t := _t
	t.ensure_both_slots_is_filled_in()
	sprite.transforms << t
}

pub fn (mut sprite Sprite) reset_size_based_on_texture(arg CommonSpriteSizeResetArgument) {
	if arg.size.x != 0 || arg.size.y != 0 {
		sprite.raw_size.x = arg.size.x
		sprite.raw_size.y = arg.size.y

		sprite.size.x = arg.size.x
		sprite.size.y = arg.size.y
	} else {
		texture := sprite.get_texture()

		sprite.raw_size.x = texture.width * arg.factor
		sprite.raw_size.y = texture.height * arg.factor

		sprite.size.x = texture.width * arg.factor
		sprite.size.y = texture.height * arg.factor
	}
}

pub fn (mut sprite Sprite) reset_attributes_based_on_transforms() {
	mut applied := []transform.TransformType{}

	// Might as well sort the transforms while we're at it
	sprite.transforms.sort(a.time.start < b.time.start)

	for i, t in sprite.transforms {
		if t.typ !in applied {
			applied << t.typ
			sprite.apply_event(t, t.time.start)
		}

		// Time
		if i == 0 {
			sprite.time.start = t.time.start	
		}

		sprite.time.start = math.min(sprite.time.start, t.time.start)
		sprite.time.end = math.max(sprite.time.end, t.time.end)
	}
}

// 
pub fn (mut sprite Sprite) is_drawable_at(time f64) bool {
	// HACKHACKHACK: New bug appeared out of nowhere, broken as of 10/4/22
	//               Was working fine the day before...
	if isnil(sprite.time) {
		logging.error("Time is nulled when checking sprite, returning false.")
		// logging.error("Amount of transforms: ${sprite.transforms.len}")
		return false // ?? huh
	}

	return time >= sprite.time.start && time <= sprite.time.end
}

// Texture
pub fn (mut sprite Sprite) get_texture() &gg.Image {
	return &sprite.textures[sprite.texture_i]
}


// Draw/Update FNs
pub fn (mut sprite Sprite) update(time f64) {
	// Old style: wont show up properly if time is too fast
	// TODO: make better updater
	for t in sprite.transforms {
		if time >= t.time.start && time <= t.time.end + 100 {
			sprite.apply_event(t, math.min(time, t.time.end)) // HACKHACHKHACK: extra 100ms to make sure the transform doesnt get skipped
		}
	}

	//for mut t in sprite.transforms {
	// 	if time >= t.time.start {
	// 		sprite.apply_event(t, time)

	// 		if time >= t.time.end {
	// 			sprite.apply_event(t, time)
	// 			sprite.transforms.delete(sprite.transforms.index(t))
	// 			continue
	// 		}
	// 	}
	// }
}
pub fn (mut sprite Sprite) draw(arg CommonSpriteArgument) {
	if sprite.is_drawable_at(arg.time) {
		size := sprite.size.scale(arg.camera.scale * arg.scale)
		pos := sprite.position.scale(arg.camera.scale).sub(sprite.origin.multiply(size)).add(arg.camera.offset)

		arg.ctx.draw_image_with_config(gg.DrawImageConfig{
			img: sprite.get_texture(),
			img_id: sprite.get_texture().id,
			img_rect: gg.Rect{
				x: f32(pos.x)
				y: f32(pos.y),
				width: f32(size.x),
				height: f32(size.y)
			},
			rotate: f32(sprite.angle)
			color: sprite.color,
			additive: sprite.additive,
		})
	}
}

pub fn (mut sprite Sprite) draw_and_update(arg CommonSpriteArgument) {}