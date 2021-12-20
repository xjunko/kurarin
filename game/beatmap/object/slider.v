module object

import math
import lib.gg

import framework.math.easing
import framework.math.vector
import framework.math.time
import framework.graphic.sprite
import framework.audio

import curves
import game.graphic

const (
	fallback_slider = false
)

pub struct Slider {
	HitObject

	pub mut:
		samples 	  []int
		sample_sets   []int
		addition_sets []int

		sliderrender &graphic.SliderRenderer = &graphic.SliderRenderer{}
		end_position  vector.Vector2
		sliderend 	  &sprite.Sprite = &sprite.Sprite{}
		curve         curves.SliderCurve
		repeated  	  f64
		pixel_length  f64
		duration      f64
		skip_offset   bool

		// HACKHACK
		last_time int
		temp_done bool
}

pub fn (mut slider Slider) play_hitsound(index int) {
	mut audio_ptr := audio.global
	mut sample := slider.samples[index]
	mut sample_set := slider.sample_sets[index]
	mut addition_sets := slider.addition_sets[index]
	point := slider.timing.get_point_at(slider.time.start + math.floor(index * slider.duration + 5))

	if sample_set == 0 {
		sample_set = slider.sample_set

		if sample_set == 0 {
			sample_set = int(point.sampleset)
		}
	}

	if addition_sets == 0 {
		addition_sets = 0 // TODO: addition set
	}

	audio_ptr.play_osu_sample(
		sample,
		sample_set
	)
}

pub fn (mut slider Slider) draw(ctx &gg.Context, time f64) {
	// HACK: fn abuse

	if time >= slider.time.start && time <= slider.time.end {
		times := int(((time - slider.time.start) / slider.duration) + 1)

		if slider.last_time != times {
			slider.play_hitsound(times - 1)
			slider.last_time = times
		}

		return
	}

	slider.play_hitsound(int(slider.repeated))
	slider.temp_done = true
}

pub fn (mut slider Slider) get_curves() []vector.Vector2 {
	t0 := f64(2 / slider.pixel_length)
	rt := f64(slider.pixel_length) / slider.curve.length
	mut points := []vector.Vector2{len: int(slider.pixel_length / 2)}
	mut t := 0.0

	for i := 0; i < int(slider.pixel_length / 2); i++ {
		points[i] = slider.curve.point_at(f64(t) * f64(rt))
		t += t0
	}

	return points
}

pub fn (mut slider Slider) initialize_object(mut ctx &gg.Context, last_object IHitObject) {
	// Init hitobject
	slider.HitObject.initialize_object(mut ctx, last_object)

	// more info
	slider.repeated = slider.data[6].f64()
	slider.pixel_length = slider.data[7].f64()
	
	// Process them pointsss
	slider.process_points()

	// from osr2mp4
	slider.duration = slider.timing.get_point_at(slider.time.start).beatduration * slider.pixel_length / (100 * slider.timing.slider_multiplier)
	slider.time.end += slider.duration * slider.repeated

	// samples
	slider.samples = []int{len: int(slider.repeated) + 1}
	slider.sample_sets = []int{len: int(slider.repeated) + 1}
	slider.addition_sets = []int{len: int(slider.repeated) + 1}


	if slider.data.len > 8 {
		data := slider.data[8].split('|')
		for i, v in data {
			slider.samples[i] = v.int()
		}
	}

	// sets
	if slider.data.len > 9 {
		data := slider.data[9].split('|')
		for i, v in data {
			items := v.split(':')
			slider.sample_sets[i] = items[0].int()
			slider.addition_sets[i] = items[1].int()
		}
	}

	// make slider follow circle eee
	slider.make_slider_follow_circle()

	// Make slider renderrrrrrer
	slider.sliderrender.time = &slider.time
	slider.sliderrender.difficulty = slider.diff
	slider.sliderrender.color = [f32(slider.color[0] / 255), f32(slider.color[1] / 255), f32(slider.color[2] / 255)]
	slider.sliderrender.curves = slider.get_curves()
	slider.sliderrender.cs = slider.diff.circleradius
	slider.sliderrender.make_pipeline()
	slider.sliderrender.special = true

	mut temp_sprites := []sprite.IDrawable{}
	temp_sprites << slider.sliderrender
	temp_sprites << slider.sprites

	slider.sprites = temp_sprites
}

pub fn (mut slider Slider) make_slider_follow_circle() {
	// Overlay
	size_ratio := ((slider.diff.circleradius) * 1.05 * 2 / 128)
	mut slider_overlay_sprite := &sprite.Sprite{
			textures: [gg.get_texture_from_skin("sliderfollowcircle")],
	}
	mut sliderb_sprite := &sprite.Sprite{
		textures: [gg.get_texture_from_skin("sliderb")]
	}

	mut slider_objects := []&sprite.Sprite{}
	slider_objects << slider_overlay_sprite
	slider_objects << sliderb_sprite

	// color
	sliderb_sprite.add_transform(typ: .color, time: time.Time{slider.time.start, slider.time.start}, before: slider.color)

	mut last_position := slider.position
	for mut object in slider_objects {
		// Movement
		offset := 16
		for temp_time := int(slider.time.start); temp_time <= int(slider.time.end); temp_time += offset {
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
			object.add_transform(typ: .move, time: time.Time{temp_time, temp_time + offset}, before: [last_position.x, last_position.y], after: [pos.x, pos.y])
		}
		// fade in
		object.add_transform(typ: .scale_factor, easing: easing.quad_out, time: time.Time{slider.time.start, slider.time.start}, before: [f64(size_ratio)])

		// DDONNEEE
		object.reset_time_based_on_transforms()
		object.reset_image_size()
		object.reset_attributes_based_on_transforms()
	}
	slider.sprites << sliderb_sprite
	slider.sprites << slider_overlay_sprite
	
}
pub fn (mut slider Slider) process_points() {
	mut slider_points := slider.data[5].split('|')
	mut slider_type := slider_points[0]
	slider_points = slider_points[1..]
	

	// NEW slider shit
	mut vector_points := []vector.Vector2{}
	vector_points << slider.position
	for points in slider_points {
		items := points.split(":")
		vector_points << vector.Vector2{items[0].f64(), items[1].f64()}
	}
	
	// println("${vector_points.len} points, Type: ${slider_type}")
	slider.curve = curves.new_slider_curve(slider_type, vector_points)		
	slider.end_position = slider.curve.point_at(math.fmod(slider.repeated, 2))
}

pub fn (mut slider Slider) hit_edge(index int, time f64, is_hit bool) {
	if index == 0 {
		slider.arm_start(is_hit, time)
	} else {
		// TODO
	}

	if is_hit {
		// slider.play_hitsound(index)
	}
}

pub fn (mut slider Slider) arm_start(clicked bool, time f64) {
	slider.HitObject.arm(clicked, time)
}

pub fn (mut slider Slider) arm(clicked bool, time f64) {
}

pub fn (mut slider Slider) get_hit_object() &HitObject {
	return slider.HitObject.get_hit_object()
}