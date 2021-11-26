module object

import math
import lib.gg

import framework.math.easing
import framework.math.vector
import framework.math.time
import framework.graphic.sprite

import curves
import game.graphic
import game.math.resolution

const (
	fallback_slider = false
)

pub struct Slider {
	HitObject

	pub mut:
		sliderrender &graphic.SliderRenderer = &graphic.SliderRenderer{}
		end_position  vector.Vector2
		sliderend 	  &sprite.Sprite = &sprite.Sprite{}
		curve         curves.SliderCurve
		repeated  	  f64
		pixel_length  f64
		duration      f64
		skip_offset   bool

}

pub fn (mut slider Slider) draw(ctx &gg.Context, time f64) {
	slider.sliderrender.draw(ctx: ctx)
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
	/* the old method
	slider.repeated = slider.data[6].f64()
	slider.pixel_length = slider.data[7].f64()
	slider.duration = (
		slider.timing.get_beat_duration(slider.time.start) * slider.pixel_length / (100 * slider.diff.slider_multiplier)
	)
	slider.time.end += slider.duration * slider.repeated
	*/

	// why do i need to do this again lol
	slider.HitObject.initialize_object(mut ctx, last_object)

	// more info
	slider.repeated = slider.data[6].f64()
	slider.pixel_length = slider.data[7].f64()
	
	// Process them pointsss
	slider.process_points()

	if slider.time.start >= 65000 && slider.time.start <= 70000 {
		println(slider.time.start)
		println(slider.timing.get_point_at(slider.time.start))
	}
	// from osr2mp4
	slider.duration = slider.timing.get_point_at(slider.time.start).beatduration * slider.pixel_length / (100 * slider.timing.slider_multiplier)
	slider.time.end += slider.duration * slider.repeated

	// println('${slider.time.start} ${slider.time.end} - ${point} ${velocity} ${cum_length} ${slider.repeated}')

	// make slider follow circle eee
	slider.make_slider_follow_circle()

	// Make slider renderrrrrrer
	slider.sliderrender.time = &slider.time
	slider.sliderrender.difficulty = slider.diff
	slider.sliderrender.color = [f32(slider.color[0] / 255), f32(slider.color[1] / 255), f32(slider.color[2] / 255)]
	slider.sliderrender.curves = slider.get_curves()
	slider.sliderrender.make_pipeline( (slider.diff.circleradius / 64.0) ) // * resolution.global.playfield_scale )
	slider.sliderrender.special = true

	slider.sprites << slider.sliderrender
}

pub fn (mut slider Slider) make_slider_follow_circle() {
	// Overlay
	slider_overlay := gg.get_texture_from_skin("sliderfollowcircle")
	mut slider_overlay_sprite := &sprite.Sprite{
			textures: [slider_overlay],
	}

	// Movement
	offset := 16
	for temp_time := int(slider.time.start); temp_time <= int(slider.time.end); temp_time += offset {
		times := int(((temp_time - slider.time.start) / slider.duration) + 1)
		t_time := (f64(temp_time) - slider.time.start - (times - 1) * slider.duration)
		rt := slider.pixel_length / slider.curve.length

		mut pos := vector.Vector2{}
		if (times % 2) == 1 {
			pos = slider.curve.point_at(rt * t_time / slider.duration)
		} else {
			pos = slider.curve.point_at((1.0 - t_time / slider.duration) * rt)
		}
		slider_overlay_sprite.add_transform(typ: .move, time: time.Time{temp_time, temp_time + offset}, before: [pos.x, pos.y])
	}

	// fade in
	slider_overlay_sprite.add_transform(typ: .scale_factor, easing: easing.quad_out, time: time.Time{slider.time.start, slider.time.start}, before: [f64(0.6)])
	// slider_overlay_sprite.add_transform(typ: .fade, time: time.Time{slider.time.start, slider.time.start}, before: [f64(0)], after: [f64(255)])

	// DDONNEEE
	slider_overlay_sprite.reset_time_based_on_transforms()
	slider_overlay_sprite.reset_image_size()
	slider_overlay_sprite.reset_attributes_based_on_transforms()

	//
	slider.sprites << slider_overlay_sprite
}
pub fn (mut slider Slider) process_points() {
	// mut size_ratio := (54.4 - 4.48 * slider.diff.cs) * 1.05 * 2 / 128
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

pub fn (mut slider Slider) arm(clicked bool, time f64) {
	slider.HitObject.arm(clicked, time)
}

pub fn (mut slider Slider) get_hit_object() &HitObject {
	return slider.HitObject.get_hit_object()
}