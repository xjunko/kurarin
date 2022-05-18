// TODO: move this somewhere else

module cursor

import time
import library.gg
import gx
import math
import rand
import sync

import framework.graphic.sprite
import framework.math.easing
import framework.math.vector
import framework.math.time as time2

import game.settings
import game.beatmap
import game.beatmap.object as gameobject
import game.skin
import game.x

const (
	used_imports = gameobject.used_imports
)

// V updated its rand library and now its returning optionals (?)
fn random_f64_in_range(min f64, max f64) f64 {
	return rand.f64_in_range(min, max) or { 0.0 }
}

pub struct Cursor {
	sprite.Sprite

	pub mut:
		mutex       &sync.Mutex = sync.new_mutex()
		ctx 	    &gg.Context = voidptr(0)
		trails      []&sprite.Sprite
		trail_color gx.Color = gx.Color{0, 25, 100, u8(255 * 0.5)}
		delta_pos   []vector.Vector2
		delta_pos_i int

		// Game control
		left_button	bool
		right_button bool
		left_mouse bool
		right_mouse bool
	mut:
		sixty_delta   f64
		last_time     f64
		last_position vector.Vector2

}

pub fn (mut cursor Cursor) draw(_ sprite.CommonSpriteArgument) {
	cursor.mutex.@lock()

	if settings.global.gameplay.cursor.style == 2 {
		for i, trail in cursor.delta_pos {
			size := cursor.size.scale(
				0.9 * (0.5 + f64(i) / f64(cursor.delta_pos.len) * 0.4)
			)

			pos := trail.sub(cursor.origin.multiply(x: size.x, y: size.y))
			cursor.ctx.draw_image_with_config(gg.DrawImageConfig{
				img: &cursor.textures[3],
				img_id: cursor.textures[3].id,
				img_rect: gg.Rect{
					x: f32(pos.x * x.resolution.playfield_scale + x.resolution.offset.x),
					y: f32(pos.y * x.resolution.playfield_scale + x.resolution.offset.y),
					width: f32(size.x * x.resolution.playfield_scale),
					height: f32(size.y * x.resolution.playfield_scale)
				},
				color: cursor.trail_color,
				additive: true
			})
		}
	} else {
		// Normal trails
		for mut trail in cursor.trails {
			if !trail.is_drawable_at(cursor.last_time) { continue }

			pos := trail.position.sub(trail.origin.multiply(x: trail.size.x, y: trail.size.y))

			cursor.ctx.draw_image_with_config(gg.DrawImageConfig{
				img: trail.get_texture(),
				img_id: trail.get_texture().id,
				img_rect: gg.Rect{
					x: f32(pos.x * x.resolution.playfield_scale + x.resolution.offset.x),
					y: f32(pos.y * x.resolution.playfield_scale + x.resolution.offset.y),
					width: f32(trail.size.x * x.resolution.playfield_scale),
					height: f32(trail.size.y * x.resolution.playfield_scale)
				},
				color: trail.color,
				additive: settings.global.gameplay.cursor.style != 0
			})
		}
	}

	// Cursor
	pos := cursor.position.sub(cursor.origin.multiply(x: cursor.size.x, y: cursor.size.y))
	
	if settings.global.gameplay.cursor.style == 2 {
		// Fancy cursor
		cursor.ctx.draw_image_with_config(gg.DrawImageConfig{
			img: &cursor.textures[2],
			img_id: cursor.textures[2].id,
			img_rect: gg.Rect{
				x: f32(pos.x * x.resolution.playfield_scale + x.resolution.offset.x),
				y: f32(pos.y * x.resolution.playfield_scale + x.resolution.offset.y),
				width: f32(cursor.size.x * x.resolution.playfield_scale),
				height: f32(cursor.size.y * x.resolution.playfield_scale)
			},
			additive: true
		})
	} else {
		// Normal boring cursor
		cursor.ctx.draw_image_with_config(gg.DrawImageConfig{
			img: &cursor.textures[0],
			img_id: cursor.textures[0].id,
			img_rect: gg.Rect{
				x: f32(pos.x * x.resolution.playfield_scale + x.resolution.offset.x),
				y: f32(pos.y * x.resolution.playfield_scale + x.resolution.offset.y),
				width: f32(cursor.size.x * x.resolution.playfield_scale),
				height: f32(cursor.size.y * x.resolution.playfield_scale)
			},
			color: cursor.color,
		})
	}
	
	cursor.mutex.unlock()
}

pub fn (mut cursor Cursor) update(time f64, delta f64) {
	cursor.mutex.@lock()

	// Delta
	// delta := time - cursor.last_time

	// Time
	cursor.Sprite.update(time) // Update the main cursor itself

	cursor.sixty_delta += delta
	// Normal trails
	if settings.global.gameplay.cursor.style == 0 && cursor.sixty_delta >= settings.global.gameplay.cursor.trail_update_rate {
		mut trail := &sprite.Sprite{textures: [cursor.textures[1]]}
		trail.add_transform(typ: .fade, easing: easing.quad_out, time: time2.Time{time, time + 150}, before: [255.0], after: [0.0])
		trail.add_transform(typ: .move, easing: easing.quad_out, time: time2.Time{time, time + 150}, before: [cursor.position.x, cursor.position.y])
		trail.add_transform(typ: .scale_factor, time: time2.Time{time, time}, before: [settings.global.gameplay.cursor.size])
		trail.reset_size_based_on_texture()
		trail.reset_attributes_based_on_transforms()
		cursor.trails << trail

		cursor.sixty_delta -= settings.global.gameplay.cursor.trail_update_rate
	} else if settings.global.gameplay.cursor.style == 1 {
		// God awful particle trail (Old)
		distance := cursor.position.distance(cursor.last_position)
		distance_real := cursor.position.sub(cursor.last_position)

		if distance != 0.0 {
			for _ in 0 .. rand.int_in_range(10, 100) or { 0 } {
				mut trail := &sprite.Sprite{textures: [cursor.textures[1]]}
				trail.add_transform(typ: .fade, easing: easing.quad_out, time: time2.Time{time, time + random_f64_in_range(100, math.max(distance * 25.0, 150))}, before: [255.0], after: [0.0])
				trail.add_transform(typ: .move, easing: easing.quad_out, time: time2.Time{time, time + random_f64_in_range(100, math.max(distance * 32.0, 150))}, before: [cursor.position.x, cursor.position.y], after: [cursor.position.x - distance_real.x + random_f64_in_range(-distance, distance), cursor.position.y - distance_real.y + random_f64_in_range(-distance, distance)])
				trail.add_transform(typ: .scale_factor, time: time2.Time{time, time}, before: [random_f64_in_range(0.05, settings.global.gameplay.cursor.size)])
				trail.add_transform(typ: .color, time: time2.Time{time, time}, before: [random_f64_in_range(0, 255), random_f64_in_range(0, 255), random_f64_in_range(0, 255)])
				trail.reset_size_based_on_texture()
				trail.reset_attributes_based_on_transforms()
				cursor.trails << trail
			}
		}
	}

	// Smoother cursor trail (wip)
	if settings.global.gameplay.cursor.style == 2 && delta > 0.0 {
		points := int(cursor.position.distance(cursor.last_position)) * 2
		cursor.delta_pos << cursor.last_position

		for i := 1; i <= points; i++ {
			cursor.delta_pos << cursor.position.sub(cursor.last_position).scale(f64(i)/f64(points)).add(cursor.last_position)
		}

		times := cursor.delta_pos.len / (2.0 * (60.0 / delta)) + 1

		if cursor.delta_pos.len > 0 {
			if int(times) < cursor.delta_pos.len {
				cursor.delta_pos = cursor.delta_pos[int(times) ..]
			} else {
				cursor.delta_pos = cursor.delta_pos[cursor.delta_pos.len ..]
			}
		}
	}


	for mut trail in cursor.trails {
		if time > trail.time.end {
			cursor.trails.delete(cursor.trails.index(trail))
			continue
		}

		trail.update(time)
	}


	// Done
	cursor.last_position.x = cursor.position.x
	cursor.last_position.y = cursor.position.y
	cursor.last_time = time

	cursor.mutex.unlock()
}

// Factory
pub fn make_cursor(mut ctx &gg.Context) &Cursor {
	mut cursor := &Cursor{ctx: ctx, always_visible: true}
	cursor.textures << skin.get_texture("cursor")
	cursor.textures << skin.get_texture("cursortrail")
	cursor.textures << skin.get_texture("cursor-top")
	cursor.textures << skin.get_texture("cursortrailfx")
	cursor.add_transform(typ: .scale_factor, time: time2.Time{0, 0}, before: [settings.global.gameplay.cursor.size])

	//
	cursor.reset_size_based_on_texture()
	cursor.reset_attributes_based_on_transforms()

	return cursor
}