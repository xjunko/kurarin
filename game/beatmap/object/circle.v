module object

import math
import library.gg

// import framework.logging
import framework.math.time
import framework.math.easing
import framework.graphic.sprite


import game.settings
import game.beatmap.difficulty
import game.beatmap.timing
import game.audio
import game.skin
import game.x

const (
	default_hitcircle_size = 128.0
	is_hidden = false
)

pub struct Circle {
	HitObject

	pub mut:
		timing           timing.Timings

		hitcircle        &sprite.Sprite = &sprite.Sprite{}
		hitcircleoverlay &sprite.Sprite = &sprite.Sprite{}
		approachcircle   &sprite.Sprite = &sprite.Sprite{}
		combotext        &sprite.NumberSprite = voidptr(0)

		sprites []sprite.ISprite
		diff    difficulty.Difficulty
		silent  bool

		sample int

		// temp shit
		last_time f64
		done      bool
		inherited bool
}

pub fn (mut circle Circle) draw(arg sprite.CommonSpriteArgument) {
	if settings.global.miscellaneous.rainbow_hitcircle {
		time := circle.last_time / 100.0
		circle.hitcircle.color.r = u8(f32(math.sin(0.3*time + 0 + 1 * 1) * 127.0 + 128.0))
		circle.hitcircle.color.g = u8(f32(math.sin(0.3*time + 2 + 1 * 1) * 127.0 + 128.0))
		circle.hitcircle.color.b = u8(f32(math.sin(0.3*time + 4 + 1 * 1) * 127.0 + 128.0))

		circle.combotext.color = circle.hitcircle.color
		circle.approachcircle.color = circle.hitcircle.color
		circle.hitcircleoverlay.color = circle.hitcircle.color // HACK: i dont think this will fuck with anything but considering this 
		                                                       //       is v and its kinda buggy, might as well put up a notice here
	}

	// Draw
	for mut sprite in circle.sprites {
		sprite.draw(arg)
	}

	// Combo
	if circle.combotext.is_drawable_at(circle.last_time) {
		// God awful
		pos := circle.combotext.position.sub(
				circle.combotext.origin
					.multiply(x: circle.combotext.size.x * circle.combotext.number_len, y: circle.combotext.size.y)
			)

		for n, img in circle.combotext.number_img {
			arg.ctx.draw_image_with_config(
				img: img,
				img_id: img.id,
				img_rect: gg.Rect{
					x: f32((pos.x + (circle.combotext.size.x * n)) * x.resolution.playfield_scale + x.resolution.offset.x),
					y: f32(pos.y * x.resolution.playfield_scale + x.resolution.offset.y),
					width: f32(circle.combotext.size.x * x.resolution.playfield_scale),
					height: f32(circle.combotext.size.y * x.resolution.playfield_scale)
				},
				color: circle.combotext.color,
				additive: circle.combotext.additive
			)
		}
	}
}

pub fn (mut circle Circle) update(time f64) bool {
	circle.last_time = time

	for mut sprite in circle.sprites {
		sprite.update(time)
	}
	circle.combotext.update(time)

	// Hitanimation, we're done
	// if time >= circle.get_start_time() && !circle.done {
	// 	// circle.arm(true, time)

	// 	// Dont play if this is inherited from a slider
	// 	// if !circle.inherited {
	// 	// 	circle.play_hitsound()
	// 	// }
		
	// 	circle.done = true

	// 	return true
	// }

	return false
}

pub fn (mut circle Circle) set_timing(t timing.Timings) {
	circle.timing = t
}

pub fn (mut circle Circle) set_difficulty(diff difficulty.Difficulty) {
	circle.diff = diff

	//
	start_time := circle.time.start - diff.preempt
	end_time := circle.time.start

	// init combo sprite
	circle.combotext = sprite.make_number_sprite(circle.combo_number)
	
	//
	if circle.inherited {
		circle.hitcircle.textures << skin.get_texture("sliderstartcircleoverlay")
		circle.hitcircleoverlay.textures << skin.get_texture("sliderstartcircle")
	} else {
		circle.hitcircle.textures << skin.get_texture("hitcircle")
		circle.hitcircleoverlay.textures << skin.get_texture("hitcircleoverlay")
	}

	circle.approachcircle.textures << skin.get_texture("approachcircle")

	circle.sprites << circle.hitcircle
	circle.sprites << circle.hitcircleoverlay
	circle.sprites << circle.approachcircle


	//
	mut circles := []sprite.ISprite{}
	circles << circle.hitcircle
	circles << circle.hitcircleoverlay
	circles << circle.combotext

	// Color
	circle.hitcircle.add_transform(typ: .color, time: time.Time{start_time, start_time}, before: circle.color)
	circle.approachcircle.add_transform(typ: .color, time: time.Time{start_time, start_time}, before: circle.color)

	// HACK: bruh
	if circle.inherited {
		circle.hitcircleoverlay.add_transform(typ: .color, time: time.Time{start_time, start_time}, before: circle.color)
	}

	for mut s in circles {
		s.add_transform(typ: .move, time: time.Time{start_time, start_time}, before: [circle.position.x, circle.position.y])
		
		if is_hidden {
			s.add_transform(typ: .fade, time: time.Time{start_time, start_time + diff.preempt * 0.4}, before: [0.0], after: [255.0])
			s.add_transform(typ: .fade, time: time.Time{start_time + diff.preempt * 0.4, start_time + diff.preempt * 0.7}, before: [255.0], after: [0.0])
		} else {
			s.add_transform(typ: .fade, time: time.Time{start_time, start_time + diff.fade_in}, before: [0.0], after: [255.0])
			s.add_transform(typ: .fade, time: time.Time{end_time, end_time}, before: [0.0], after: [255.0])
		}

		// Done
		s.reset_size_based_on_texture(factor: (circle.diff.circle_radius * 1.05 * 2) / 128)
		s.reset_attributes_based_on_transforms()
	}


	// Approach circle 
	if !is_hidden || circle.id == 0 {
		circle.approachcircle.add_transform(typ: .move, time: time.Time{start_time, start_time}, before:[circle.position.x, circle.position.y])
		circle.approachcircle.add_transform(typ: .fade, time: time.Time{start_time, math.min(end_time, end_time - diff.preempt + diff.fade_in * 2.0)}, before: [0.0], after: [229.5]) // 0.9
		circle.approachcircle.add_transform(typ: .fade, time: time.Time{end_time, end_time}, before: [0.0], after: [0.0])
		circle.approachcircle.add_transform(typ: .scale_factor, time: time.Time{start_time, end_time}, before: [4.0], after: [1.0])
		circle.approachcircle.reset_size_based_on_texture(factor: (circle.diff.circle_radius * 1.05 * 2)/ 128)
		circle.approachcircle.reset_attributes_based_on_transforms()
	}
}

pub fn (mut circle Circle) arm(clicked bool, _time f64) {
	circle.approachcircle.reset_transform()
	circle.combotext.reset_transform()
	circle.hitcircleoverlay.reset_transform()
	circle.hitcircle.reset_transform()
	

	start_time := _time
	end_scale := 1.4

	// sayonara approach circle-kun >w<
	circle.approachcircle.add_transform(typ: .fade, time: time.Time{start_time, start_time}, before: [0.0])

	if clicked && !is_hidden {
		end_time := start_time + difficulty.hit_fade_out

		// scale
		circle.hitcircle.add_transform(typ: .scale_factor, easing: easing.quad_out, time: time.Time{start_time, end_time}, before: [1.0], after: [end_scale])
		circle.hitcircleoverlay.add_transform(typ: .scale_factor, easing: easing.quad_out, time: time.Time{start_time, end_time}, before: [1.0], after: [end_scale])

		// fade
		circle.hitcircle.add_transform(typ: .fade, time: time.Time{start_time, end_time}, before: [255.0], after: [0.0])
		circle.hitcircleoverlay.add_transform(typ: .fade, time: time.Time{start_time, end_time}, before: [255.0], after: [0.0])
		circle.combotext.add_transform(typ: .fade, time: time.Time{start_time, end_time}, before: [255.0], after: [0.0])
	} else {
		// Hidden or missed, same shit
		end_time := start_time + 60.0
		circle.hitcircle.add_transform(typ: .fade, easing: easing.quad_out, time: time.Time{start_time, end_time}, before: [f64(circle.hitcircle.color.a)], after: [0.0])
		circle.hitcircleoverlay.add_transform(typ: .fade, easing: easing.quad_out, time: time.Time{start_time, end_time}, before: [f64(circle.hitcircleoverlay.color.a)], after: [0.0])
		circle.combotext.add_transform(typ: .fade, easing: easing.quad_out, time: time.Time{start_time, end_time}, before: [f64(circle.combotext.color.a)], after: [0.0])
	}

	//  resets
	circle.hitcircle.reset_time_based_on_transforms()
	circle.hitcircleoverlay.reset_time_based_on_transforms()
	circle.approachcircle.reset_time_based_on_transforms()

}

pub fn (mut circle Circle) shake(_time f64) {
	for mut sprite in circle.sprites {
		sprite.remove_transform_by_type(.move_x)
		sprite.add_transform(typ: .move_x, time: time.Time{_time, _time + 20}, before: [circle.position.x + 0], after: [circle.position.x + 8])
		sprite.add_transform(typ: .move_x, time: time.Time{_time + 20, _time + 40}, before: [circle.position.x + 8], after: [circle.position.x - 8])
		sprite.add_transform(typ: .move_x, time: time.Time{_time + 40, _time + 60}, before: [circle.position.x - 8], after: [circle.position.x + 8])
		sprite.add_transform(typ: .move_x, time: time.Time{_time + 60, _time + 80}, before: [circle.position.x + 8], after: [circle.position.x - 8])
		sprite.add_transform(typ: .move_x, time: time.Time{_time + 80, _time + 100}, before: [circle.position.x - 8], after: [circle.position.x + 8])
		sprite.add_transform(typ: .move_x, time: time.Time{_time + 100, _time + 120}, before: [circle.position.x + 8], after: [circle.position.x + 0])
	}
}

pub fn (mut circle Circle) play_hitsound() {
	// play hitsound
	point := circle.timing.get_point_at(circle.time.start)

	mut index := circle.hitsound.custom_index
	mut sample_set := circle.hitsound.sample_set

	if index == 0 {
		index = point.sample_index
	}

	if sample_set == 0 {
		sample_set = point.sample_set
	}

	
	audio.play_sample(
		sample_set,
		circle.hitsound.addition_set,
		circle.sample,
		index,
		point.sample_volume
	)
}

pub fn make_circle(items []string) &Circle {
	mut hcircle := &Circle{
		HitObject: common_parse(items, 5)
	}
	hcircle.sample = items[4].int()

	return hcircle
}

