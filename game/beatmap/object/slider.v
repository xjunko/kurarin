module object

import library.gg
import math

import framework.graphic.sprite
import framework.math.easing
import framework.math.vector
import framework.math.time
import framework.logging

import game.beatmap.difficulty
import game.beatmap.timing
import game.audio
import game.skin
import game.x

import curves
import graphic


pub struct Slider {
	HitObject

	pub mut:
		timing          timing.Timings
		hitcircle 		&Circle

		// Slider shit
		repeated        int
		pixel_length    f64
		duration        f64		
		points          []vector.Vector2
		curve           curves.SliderCurve

		// 
		slider_overlay_sprite &sprite.Sprite = &sprite.Sprite{}
		slider_b_sprite  	  &sprite.Sprite = &sprite.Sprite{}
		

		sprites         	  []&sprite.Sprite
		slider_renderer_attr  &graphic.SliderRendererAttr = voidptr(0)

		// Sample
		samples         []int
		sample_sets     []int
		addition_sets   []int // TODO

		// temp
		done             bool
		last_slider_time int
		last_time        f64

}

pub fn (mut slider Slider) set_combo_number(combo int) {
	slider.hitcircle.set_combo_number(combo)
}

pub fn (mut slider Slider) draw(arg sprite.CommonSpriteArgument) {
	slider.hitcircle.draw(arg)
	// Draw the easy stuff first
	for mut sprite in slider.sprites {
		if sprite.is_drawable_at(slider.last_time) {
			size := sprite.size.scale(slider.music_boost)
			pos := sprite.position.sub(sprite.origin.multiply(size))
			arg.ctx.draw_image_with_config(gg.DrawImageConfig{
					img: sprite.get_texture(),
					img_id: sprite.get_texture().id,
					img_rect: gg.Rect{
						x: f32(pos.x * x.resolution.playfield_scale + x.resolution.offset.x),
						y: f32(pos.y * x.resolution.playfield_scale + x.resolution.offset.y),
						width: f32(size.x * x.resolution.playfield_scale),
						height: f32(size.y * x.resolution.playfield_scale)
					},
					color: sprite.color
					rotate: f32(sprite.angle)
			})
		}
	}

	// // Slider Vertex shit
	// mut start_index := 0
	// mut end_index := int(slider.pixel_length / 2.0)

	// if slider.last_time < slider.time.start - slider.diff.preempt / 2.0 {
	// 	progress := f64(slider.last_time - (slider.time.start-(slider.diff.preempt)))/(slider.diff.preempt/2)
	// 	end_index = int(f64(end_index) * progress)
	// } else if slider.last_time >= slider.time.start && slider.last_time <= slider.time.end {
	// 	times := int(((slider.last_time - slider.time.start) / slider.duration) + 1)

	// 	if times == slider.repeated {
	// 		ttime := slider.last_time - slider.time.start - f64(times-1) * slider.duration

	// 		if (times % 2) == 1 {
	// 			progress := ttime / slider.duration
	// 			start_index = int(f64(end_index)*progress)
	// 		} else {
	// 			progress := 1.0 - ttime / slider.duration
	// 			end_index = int(f64(end_index) * progress)
	// 		}
	// 	}
	// } else if slider.last_time > slider.time.end {
	// 	start_index = end_index
	// }

	// Draw slider body
	// TODO: alpha
	if slider.last_time >= slider.time.start - slider.diff.preempt && slider.last_time <= slider.time.end {
		slider.slider_renderer_attr.update_vertex_progress(0, 0)
		slider.slider_renderer_attr.draw_slider(slider.hitcircle.hitcircle.color.a)
		return
	}
}

pub fn (mut slider Slider) play_hitsound(index int) {
	slider.play_hitsound_generic(
		slider.sample_sets[index],
		slider.addition_sets[index],
		slider.samples[index],
		slider.timing.get_point_at(slider.time.start + math.floor(f64(index) * slider.duration) + 5)
	)
}

pub fn (mut slider Slider) play_hitsound_generic(sample_set_ int, addition_set_ int, sample int, point timing.TimingPoint) {
	mut sample_set := sample_set_
	mut addition_set := addition_set_

	if sample_set == 0 {
		sample_set = slider.hitsound.sample_set

		if sample_set == 0 {
			sample_set = point.sample_set
		}
	}

	if addition_set == 0 {
		addition_set = slider.hitsound.addition_set
	}

	audio.play_sample(
		sample_set,
		addition_set,
		sample,
		point.sample_index,
		point.sample_volume
	)
}

pub fn (mut slider Slider) update(time f64) bool {
	slider.last_time = time

	slider.hitcircle.update(time)

	for mut sprite in slider.sprites {
		sprite.update(time)
	}

	// Generate shader -1000ms before
	if time >= (slider.time.start - 1000) && isnil(slider.slider_renderer_attr) {
		slider.generate_slider_renderer()
	}

	// Hitsounds
	if time >= slider.time.start && time <= slider.time.end {
		times := int(((time - slider.time.start) / slider.duration) + 1)
		
		if slider.last_slider_time != times {
			slider.play_hitsound(times - 1)
			slider.last_slider_time = times
		}

		return false
	}


	// Last hit
	if time >= slider.time.end && !slider.done {
		slider.play_hitsound(int(slider.repeated))
		slider.done = true

		return true
	}


	return false
}

pub fn (mut slider Slider) post_update(time f64) {
	logging.debug("Freeing slider.")
	slider.slider_renderer_attr.free()
}

pub fn (mut slider Slider) set_boost_level(boost f32) {
	slider.HitObject.set_boost_level(boost)
	slider.hitcircle.set_boost_level(boost)
}

pub fn (mut slider Slider) set_timing(t timing.Timings) {
	slider.timing = t
	slider.hitcircle.set_timing(t)

	// Slider data
	slider.repeated = slider.data[6].int()
	slider.pixel_length = slider.data[7].f64()

	// Duration per one round (duration*n if its a reverse slider)
	slider.duration = slider.timing.get_point_at(slider.time.start).get_beat_length() * slider.pixel_length / (100 * slider.timing.slider_multiplier)
	slider.time.end += slider.duration * f64(slider.repeated)

	// Samples
	slider.samples = []int{len: int(slider.repeated) + 1}
	slider.sample_sets = []int{len: int(slider.repeated) + 1}
	slider.addition_sets = []int{len: int(slider.repeated) + 1}

	// Sample
	if slider.data.len > 8 {
		data := slider.data[8].split("|")
		for i, v in data {
			slider.samples[i] = v.int()
		}
	}

	// Sets
	if slider.data.len > 9 {
		data := slider.data[9].split("|")
		for i, v in data {
			items := v.split(":")
			slider.sample_sets[i] = items[0].int()
			slider.addition_sets[i] = items[1].int()
		}
	}
}

pub fn (mut slider Slider) generate_slider_points() {
	logging.debug("Generating slider path!")

	slider_points_raw := slider.data[5].split("|")
	slider_type := slider_points_raw[0]

	mut slider_points := []vector.Vector2{}
	slider_points << slider.position
	slider_points << slider_points_raw[1..].map(fn (data string) vector.Vector2 {
		items := data.split(":")
		return vector.Vector2{items[0].f64(), items[1].f64()}
	})

	
	// oh god
	slider.curve = curves.new_slider_curve(slider_type, slider_points)
	slider.end_position = slider.curve.point_at(slider.repeated % 2)

	// Done
	logging.debug("Done generating slider path!")
}

pub fn (mut slider Slider) generate_slider_follow_circles() {
	size_ratio := f64((slider.diff.circle_radius * 1.05 * 2) / 128)

	// not poggers
	slider.slider_overlay_sprite.textures << skin.get_texture("sliderfollowcircle")
	slider.slider_b_sprite.textures << skin.get_texture("sliderb")

	mut slider_sprites := []&sprite.Sprite{}
	slider_sprites << slider.slider_overlay_sprite
	slider_sprites << slider.slider_b_sprite

	// Color
	slider.slider_b_sprite.add_transform(typ: .color, time: time.Time{slider.time.start, slider.time.start}, before: slider.color)

	// The thing taht slider circle does
	slider.slider_overlay_sprite.add_transform(typ: .scale_factor, time: time.Time{slider.time.start, slider.time.start + 160.0}, before: [size_ratio * 0.75], after: [size_ratio])
	slider.slider_overlay_sprite.add_transform(typ: .scale_factor, time: time.Time{slider.time.end, slider.time.end + 160.0}, before: [size_ratio], after: [size_ratio * 0.75])

	// Movement
	mut last_position := slider.position

	for i, mut sprite in slider_sprites {
		// Movement
		offset := 16

		for temp_time := int(slider.time.start); temp_time <= int(slider.time.end) + offset; temp_time += offset {
			times := int(((temp_time - slider.time.start) / slider.duration) + 1)
			t_time := (f64(temp_time) - slider.time.start - (times - 1) * slider.duration)
			rt := slider.pixel_length / slider.curve.length

			mut pos := vector.Vector2{}
			if (times % 2) == 1 {
				pos = slider.curve.point_at(rt * t_time / slider.duration)
				last_position = slider.curve.point_at(rt * (t_time - offset) / slider.duration)
			} else {
				pos = slider.curve.point_at((1.0 - t_time / slider.duration) * rt)
				last_position = slider.curve.point_at((1.0 - (t_time - offset) / slider.duration) * rt)
			}
			sprite.add_transform(typ: .move, time: time.Time{temp_time, temp_time + offset}, before: [last_position.x, last_position.y], after: [pos.x, pos.y])
		}

		// Just incase
		// sprite.add_transform(typ: .move, time: time.Time{slider.time.end - offset, slider.time.end}, before: [last_position.x, last_position.y], after: [slider.end_position.x, slider.end_position.y])

		// Fadeout
		sprite.add_transform(typ: .scale_factor, time: time.Time{slider.time.start, slider.time.start}, before: [size_ratio])

		// This is utterly retarded
		// 0 is slider_overlay
		// 1 is slider_b
		if i == 0 {
			sprite.add_transform(typ: .fade, time: time.Time{slider.time.end, slider.time.end + 160.0}, before: [255.0], after: [0.0])
		} else {
			sprite.add_transform(typ: .fade, time: time.Time{slider.time.end, slider.time.end + 16.0}, before: [255.0], after: [0.0])
		}
		
	
		// Done
		sprite.reset_size_based_on_texture()
		sprite.reset_attributes_based_on_transforms()
	}

	slider.sprites << slider.slider_overlay_sprite
	slider.sprites << slider.slider_b_sprite
}

pub fn (mut slider Slider) generate_slider_repeat_circle() {
	if slider.repeated < 2 { return }
	
	slider.get_slider_points() // Make slider points

	size_ratio := f64((slider.diff.circle_radius * 1.05 * 2) / 128)

	for i := 1; i <= slider.repeated; i++ {
		if i == slider.repeated {
			return // This is the last round, return
		}

		circle_time := slider.time.start + math.floor(slider.duration * f64(i))
		mut appear_time := slider.time.start - math.floor(slider.diff.preempt)

		if i > 1 {
			appear_time = circle_time - math.floor(slider.duration * 2)
		}

		mut position := slider.position
		mut look_at := slider.position

		if (i % 2) == 1 {
			position = slider.points[slider.points.len - 1]
		} else {
			look_at = slider.points[slider.points.len - 1]
		}

		mut sprite := &sprite.Sprite{}
		sprite.textures << skin.get_texture("reversearrow")
		sprite.add_transform(typ: .scale_factor, time: time.Time{appear_time, appear_time}, before: [size_ratio])
		sprite.add_transform(typ: .angle, time: time.Time{appear_time, appear_time}, before: [look_at.angle_rv(position)])
		sprite.add_transform(typ: .move, time: time.Time{appear_time, appear_time}, before: [position.x, position.y])
		sprite.add_transform(typ: .fade, time: time.Time{appear_time, circle_time}, before: [0.0], after: [255.0])
		sprite.add_transform(typ: .fade, time: time.Time{circle_time, circle_time + slider.diff.preempt / 2.0}, before: [255.0], after: [0.0])
		sprite.add_transform(typ: .scale_factor, easing: easing.quad_out, time: time.Time{circle_time, circle_time + slider.diff.preempt / 2.0}, before: [size_ratio], after: [size_ratio * 1.2])
		sprite.reset_size_based_on_texture()
		sprite.reset_attributes_based_on_transforms()

		slider.sprites << sprite
	}
}

pub fn (mut slider Slider) generate_slider_renderer() {
	slider.slider_renderer_attr = graphic.make_slider_renderer_attr(
		slider.diff.circle_radius, slider.get_slider_points(), slider.pixel_length
	)
}

pub fn (mut slider Slider) get_slider_points() []vector.Vector2 {
	if slider.points.len == 0 {
		t0 := f64(2 / slider.pixel_length)
		rt := f64(slider.pixel_length) / slider.curve.length
		slider.points = []vector.Vector2{len: int(slider.pixel_length / 2)}
		mut t := 0.0

		for i := 0; i < int(slider.pixel_length / 2); i++ {
			slider.points[i] = slider.curve.point_at(f64(t) * f64(rt))
			t += t0
		}
	}

	return slider.points
}

pub fn (mut slider Slider) set_difficulty(diff difficulty.Difficulty) {
	slider.diff = diff
	slider.hitcircle.set_difficulty(diff)

	// Make points n shit
	slider.generate_slider_points()
	slider.generate_slider_repeat_circle()
	slider.generate_slider_follow_circles()
}


pub fn make_slider(items []string) &Slider {
	mut hslider := &Slider{
		HitObject: common_parse(items, 10),
		hitcircle: make_circle(items)
	}

	hslider.hitcircle.inherited = true

	return hslider
}
