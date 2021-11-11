module object

import math
import lib.gg
import gx

import framework.math.vector
import framework.math.time
import framework.math.easing
import framework.graphic.sprite

import curves
import game.math.difficulty
// import game.graphic

const (
	fallback_slider = true
)

pub struct Slider {
	HitObject

	pub mut:
		// sliderrender &graphic.SliderRenderer = &graphic.SliderRenderer{}
		end_position vector.Vector2
		sliderend 	 &sprite.Sprite = &sprite.Sprite{}
		points    	 []vector.Vector2
		curve        curves.Linear
		repeated  	 f64
		pixel_length f64
		duration     f64

}

pub fn (mut slider Slider) draw(ctx &gg.Context, time f64) {
}

pub fn (mut slider Slider) initialize_object(mut ctx &gg.Context, last_object IHitObject) {
	// duration and shit - not accurate
	slider.repeated = slider.data[6].f64()
	slider.pixel_length = slider.data[7].f64()
	slider.duration = (
		slider.timing.get_beat_duration(slider.time.start) * slider.pixel_length / (100 * slider.diff.slider_multiplier)
	)
	
	slider.time.end += slider.duration * slider.repeated

	// why do i need to do this again lol
	slider.HitObject.initialize_object(mut ctx, last_object)
	//
	slider.process_points()

	//
	/*
	slider.sliderrender.time = &slider.time
	slider.sliderrender.points = slider.points
	slider.sliderrender.process()

	// 
	slider.sprites << slider.sliderrender
	*/
}

pub fn (mut slider Slider) check_if_mouse_clicked_on_hitobject(x f64, y f64, time f64, osu_space bool) {
	slider.HitObject.check_if_mouse_clicked_on_hitobject(x, y, time, osu_space) // dont really care about slider stuff atm
}

// TODO: temporary
// GOD BLESS ME
pub fn (mut slider Slider) process_points() {
	mut size_ratio := (54.4 - 4.48 * slider.diff.cs) * 1.05 * 2 / 128

	mut slider_points := slider.data[5].split('|')
	mut slider_type := slider_points[0]
	slider_points = slider_points[1..]
	slider_body_temp := gg.get_texture_from_skin('hitcircleoverlay')
	

	if !fallback_slider {
		// NEW slider shit
		mut vector_points := []vector.Vector2{}
		vector_points << slider.position
		for points in slider_points {
			items := points.split(":")
			vector_points << vector.Vector2{items[0].f64(), items[1].f64()}
		}

		if slider_type == 'P' {
			slider_type = 'L' // Perfetc is fucked atm
		}

		slider.points = curves.create_curve(slider_type, vector_points, slider.pixel_length)
		
		slider.end_position = slider.points[slider.points.len - 1] // get the last points
		slider.curve = curves.Linear{
			slider.points[0],
			slider.points[slider.points.len - 1]
		}
		
		for position in slider.points {
			mut sprite := &sprite.Sprite{
				textures: [slider_body_temp],
				color: gx.Color{127, 127, 127, 255}
			}

			// position := slider.curve.point_at(f64(t) / f64(1000))
			sprite.add_transform(typ: .scale_factor, time: time.Time{slider.time.start, slider.time.start}, before: [f64(1)])
			sprite.add_transform(typ: .fade, time: time.Time{slider.time.start - slider.diff.preempt, slider.time.start}, before: [f64(0)], after: [f64(255)])
			sprite.add_transform(typ: .fade, time: time.Time{slider.time.end, slider.time.end + difficulty.hit_fade_out}, before: [f64(255)], after: [f64(0)])
			sprite.add_transform(typ: .move, easing: easing.quad_out, time: time.Time{slider.time.start - slider.diff.preempt, slider.time.start}, before: [slider.position.x, slider.position.y], after: [position.x, position.y])

			//
			sprite.reset_time_based_on_transforms()
			sprite.reset_attributes_based_on_transforms()
			sprite.reset_image_size()
			sprite.change_size(size: 
				vector.Vector2{
					slider.hitcircle.image().width * size_ratio, 
					slider.hitcircle.image().height * size_ratio
				}
			)

			//
			mut first := []sprite.IDrawable{}
			first << sprite
			first << slider.sprites
			slider.sprites = first
		}
	} else {
		if slider_points.len == 0 {
			println('> Fucked slider data: ${slider.data}')
			return // huh
		}

		// Old chiller slider code
		last_point := slider_points[slider_points.len - 1].split(':')

		start_position := slider.position
		end_position := vector.Vector2{last_point[0].f64(), last_point[1].f64()}
		slider.curve = curves.Linear{
			start_position,
			end_position
		}

		// HACKHACKHACK: Duplicate code
		quality := 100

		for t := 0; t < 1000; t += quality {
			mut sprite := &sprite.Sprite{
				textures: [slider_body_temp],
			}

			position := slider.curve.point_at(f64(t) / f64(1000))
			sprite.add_transform(typ: .scale_factor, time: time.Time{slider.time.start, slider.time.start}, before: [f64(1)])
			sprite.add_transform(typ: .fade, time: time.Time{slider.time.start - slider.diff.preempt, slider.time.start}, before: [f64(0)], after: [f64(255)])
			sprite.add_transform(typ: .fade, time: time.Time{slider.time.end, slider.time.end + difficulty.hit_fade_out}, before: [f64(255)], after: [f64(0)])
			sprite.add_transform(typ: .move, easing: easing.quad_out, time: time.Time{slider.time.start - slider.diff.preempt, slider.time.start}, before: [slider.position.x, slider.position.y], after: [position.x, position.y])

			//
			sprite.reset_time_based_on_transforms()
			sprite.reset_attributes_based_on_transforms()
			sprite.reset_image_size()
			sprite.change_size(size: 
				vector.Vector2{
					slider.hitcircle.image().width * size_ratio, 
					slider.hitcircle.image().height * size_ratio
				}
			)

			sprite.color = gx.Color{127, 127, 127, 255}

			// if the last one
			
			if (t + quality) >= 1000 {
				sprite.remove_all_transform_with_type(.fade)
				sprite.remove_all_transform_with_type(.scale_factor)
				
				sprite.add_transform(typ: .fade, time: time.Time{slider.time.start - slider.diff.preempt, slider.time.start}, before: [f64(0)], after: [f64(255)])
				sprite.add_transform(typ: .fade, time: time.Time{slider.time.end, slider.time.end + difficulty.hit_fade_out}, before: [f64(255)], after: [f64(0)])
				sprite.add_transform(typ: .scale_factor, time: time.Time{slider.time.end, slider.time.end + difficulty.hit_fade_out}, before: [f64(1)], after: [f64(1.4)])
				sprite.add_transform(typ: .color, time: time.Time{slider.time.start, slider.time.start}, before: slider.HitObject.color)

				sprite.reset_time_based_on_transforms()
				sprite.reset_attributes_based_on_transforms()

				// on top
				slider.sliderend = sprite
				slider.sprites << sprite
			} else {
				// put the slider body first so itll be at the back of everything
				mut first := []sprite.IDrawable{}
				first << sprite
				first << slider.sprites
				slider.sprites = first
			}
		}
	}
	

	/*
	unsafe {
		slider.points.free()
	}
	*/
}