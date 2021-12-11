module logic

import math
import game.beatmap.object

struct TickPoint {
	pub mut:
		time   i64
		edge_i int
}

pub struct Slider {
	pub mut:
		logic &StandardLogic = voidptr(0)
		hitslider &object.Slider  = voidptr(0)
		player &PlayerReprensent = voidptr(0)

		fade_time f64
		last_slider_time f64

		//
		points []TickPoint

		// hits
		start_result HitResult
		is_start_hit bool
		is_hit bool
		sliding bool
		down_button int
}

pub fn (slider Slider) get_number() int {
	return slider.hitslider.id
}

pub fn (slider Slider) get_fade_time() f64 {
	return f64(
		slider.hitslider.time.start - slider.fade_time
	)
}

pub fn (mut slider Slider) init(logic &StandardLogic, hitslider &object.IHitObject, player &PlayerReprensent) {
	unsafe {
		slider.logic = logic
		slider.player = player

		if hitslider is object.Slider {
			slider.hitslider = hitslider 
		} else {
			panic("THE FUCK: ${hitslider.type_name()}")
		}
	}

	slider.fade_time = f64(1000000)
	slider.fade_time = f64(math.min(
		slider.fade_time, player.difficulty.preempt
	))

	// slider.start_result = .miss
}

pub fn (mut slider Slider) update_for(time f64, _ bool) bool {
	if time != slider.last_slider_time {
		slider.last_slider_time = time
	}
	// slider_position := slider.hitslider.position

	if time >= slider.hitslider.time.start && !slider.is_hit {
		// lmao no
	}

	// HACK HACK
	if time >= slider.hitslider.time.start && !slider.is_hit && !slider.hitslider.temp_done {
		slider.hitslider.draw(0, time)
	}
	

	return true
}

pub fn (mut slider Slider) update_click_for(time f64) bool {
	clicked := slider.player.left_cond_e || slider.player.right_cond_e
	radius := slider.player.difficulty.circleradius
	in_range := slider.player.position.distance(slider.hitslider.position) <= radius

	if clicked && !slider.is_start_hit && !slider.is_hit {
		action := slider.logic.can_be_hit(time, mut slider)

		if in_range {
			if action == .click {
				if slider.player.left_cond_e {
					slider.player.left_cond_e = false
				} else if slider.player.right_cond_e {
					slider.player.right_cond_e = false
				}

				if slider.player.left_cond {
					slider.down_button = 1
				} else if slider.player.right_cond {
					slider.down_button = 2
				} else {
					slider.down_button = 0
				}

				mut hit := HitResult.slidermiss
				relative := f64(math.abs(time - slider.hitslider.time.start))

				if relative < slider.player.difficulty.hit300 {
					slider.start_result = .hit300
				} else if relative < slider.player.difficulty.hit100 {
					slider.start_result = .hit100
				} else if relative < slider.player.difficulty.hit50 {
					slider.start_result = .hit50
				} else {
					slider.start_result = .miss
				}

				if slider.start_result != .miss {
					hit = .sliderstart
				}

				if hit != .ignore {
					slider.hitslider.hit_edge(0, time, hit != .slidermiss)
					slider.is_start_hit = true
				}
			} else {
				slider.player.left_cond_e = false
				slider.player.right_cond_e = false
			}
		}
	}

	return true
}

pub fn (mut slider Slider) update_post_for(time f64) bool {

	if time > slider.hitslider.time.start + slider.player.difficulty.hit50 && !slider.is_start_hit {
		slider.hitslider.arm_start(false, time)

		if slider.player.left_cond {
			slider.down_button = 1
		} else if slider.player.right_cond {
			slider.down_button = 2
		} else {
			slider.down_button = 0
		}

		slider.is_start_hit = true
		slider.start_result = .miss
	}

	if time >= slider.hitslider.time.end && !slider.is_hit {
		
	}

	return true
}

pub fn (slider &Slider) get_object() &object.IHitObject {
	return slider.hitslider
}