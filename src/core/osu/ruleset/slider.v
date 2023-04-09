module ruleset

import math

import framework.math.vector

// import core.osu.beatmap.difficulty
import core.osu.beatmap.object

const (
	left_button = Buttons(1 << 0)
	right_button = Buttons(1 << 1)
)

pub struct SliderState {
	pub mut:
		down_button Buttons
		is_start_hit bool
		is_hit bool
		points []TickPoint
		scored int
		missed int
		slide_start f64
		sliding bool
		start_result HitResult
}

pub struct TickPoint {
	pub mut:
		time f64
		score_given HitResult
		edge_num int
}

pub struct Slider {
	pub mut:
		ruleset &Ruleset = voidptr(0)
		hitslider &object.Slider = voidptr(0)
		players []&DifficultyPlayer
		state []SliderState
		fade_start_relative f64

		last_slider_time f64
		slider_position vector.Vector2
}

pub fn (slider &Slider) get_number() i64 {
	return slider.hitslider.get_id()
}

pub fn (slider &Slider) is_sliding(player &DifficultyPlayer) bool {
	return slider.state[0].sliding
}

pub fn (mut slider Slider) init(ruleset &Ruleset, hitobject object.IHitObject, players []&DifficultyPlayer) {
	slider.ruleset = unsafe { ruleset }
	slider.players = players
	slider.state = []SliderState{}

	mut t_object := unsafe { &hitobject }
	if mut t_object is object.Slider {
		slider.hitslider = t_object
	}

	slider.fade_start_relative = 100000.0

	for mut player in slider.players {
		slider.fade_start_relative = math.min<f64>(slider.fade_start_relative, player.diff.preempt)
		slider.state << &SliderState{}
		slider.state[0].start_result = HitResult.miss

		mut edge_number := 1

		for point in slider.hitslider.score_points {
			if point.is_reverse {
				slider.state[0].points << TickPoint{point.time, HitResult.slider_repeat, edge_number}
				edge_number++
			} else {
				slider.state[0].points << TickPoint{point.time, HitResult.slider_point, -1}
			}
		}

		if slider.state[0].points.len > 0 {
			slider.state[0].points[slider.state[0].points.len - 1].time =  math.max<f64>((slider.hitslider.time.start)+(slider.hitslider.time.end-slider.hitslider.time.start)/2, (slider.hitslider.time.end)-36) //slider ends 36ms before the real end for scoring
			slider.state[0].points[slider.state[0].points.len - 1].score_given = HitResult.slider_end
		}
	}
}

pub fn (mut slider Slider) update_click_for(_player &DifficultyPlayer, time f64) bool {
	mut state := &slider.state[0]
	mut player := unsafe { &_player }

	position := slider.hitslider.position
	clicked := player.left_cond_e || player.right_cond_e

	radius := player.diff.circle_radius

	// TODO: Relax2
	// https://github.com/Wieku/danser-go/blob/master/app/rulesets/osu/slider.go#L103

	in_radius := player.cursor.position.distance(position) <= radius

	if clicked && !state.is_start_hit && !state.is_hit {
		action := slider.ruleset.can_be_hit(time, mut slider, player)

		if in_radius {
			if action == .click {
				if player.left_cond_e {
					player.left_cond_e = false
				} else if player.right_cond_e {
					player.right_cond_e = false
				}

				if player.left_cond {
					state.down_button = left_button
				} else if player.right_cond {
					state.down_button = right_button
				} else {
					state.down_button = player.mouse_down_button
				}

				mut hit := HitResult.slider_miss
				mut combo := ComboResult.reset
				relative := math.abs<f64>(time - slider.hitslider.time.start)

				if relative < player.diff.hit300 {
					state.start_result = .hit300
				} else if relative < player.diff.hit100 {
					state.start_result = .hit100
				} else if relative < player.diff.hit50 {
					state.start_result = .hit50
				} else {
					state.start_result = .miss
				}

				if state.start_result != .miss {
					hit = .slider_start
					combo = .increase
				}

				if hit != .ignore {
					if slider.players.len == 1 {
						// TODO: https://github.com/Wieku/danser-go/blob/master/app/rulesets/osu/slider.go#L149
						slider.hitslider.hit_edge(0, time, hit != .slider_miss)
					}

					slider.ruleset.send_result(time, mut player.cursor, mut slider, position, hit, combo)

					state.is_start_hit = true
				}
			} else {
				player.left_cond_e = false
				player.right_cond_e = false
			}
		} else if action == .click {
			// TODO: Send Result
		}
	}

	return state.is_start_hit
}

pub fn (mut slider Slider) update_for(_player &DifficultyPlayer, time f64, process_slider_ends_ahead bool) bool {
	mut state := &slider.state[0]
	mut player := unsafe { &_player }

	mut slider_position := vector.Vector2{}

	// TODO: Mod support
	if time != slider.last_slider_time {
		slider.slider_position = slider.hitslider.get_position_at_lazer(time)
		slider.last_slider_time = time
	}

	slider_position = slider.slider_position

	if time >= slider.hitslider.time.start && !state.is_hit {
		mut mouse_down_acceptable := false
		mut mouse_down_acceptable_swap := player.game_down_state &&
				!(player.last_button == (left_button | right_button) &&
					player.last_button2 == player.mouse_down_button)

		if player.game_down_state {
			if state.down_button == Buttons(0) || (player.mouse_down_button != (left_button | right_button) && mouse_down_acceptable_swap) {
				state.down_button = Buttons(0)

				if player.left_cond {
					state.down_button = left_button
				} else if player.right_cond {
					state.down_button = right_button
				} else {
					state.down_button = player.mouse_down_button
				}

				mouse_down_acceptable = true
			} else if (player.mouse_down_button & state.down_button) > 0 {
				mouse_down_acceptable = true
			}
		} else {
			state.down_button = Buttons(0)
		}

		mouse_down_acceptable = mouse_down_acceptable || mouse_down_acceptable_swap //|| // TODO: Relax
		mut radius_needed := player.diff.circle_radius

		if state.sliding {
			radius_needed *= 2.4
		}

		allowable := mouse_down_acceptable && player.cursor.position.distance(slider_position) <= radius_needed

		if allowable && !state.sliding {
			state.sliding = true
			state.slide_start = time

			if slider.players.len == 1 {
				slider.hitslider.init_slide(time)
			}
		}

		mut points_passed := 0

		for i, point in state.points {
			if point.time > time && !(i == state.points.len - 1 && process_slider_ends_ahead && point.time - time == 1) {
				break
			}

			points_passed++
		}

		if state.scored + state.missed < points_passed {
			index := state.scored + state.missed
			mut point := &state.points[index]

			if allowable && state.slide_start <= point.time {
				state.scored++
				slider.ruleset.send_result(time, mut player.cursor, mut slider, slider_position, .slider_point, .increase)
			} else {
				state.missed++

				mut combo := ComboResult.reset 

				if (state.scored + state.missed) == state.points.len {
					combo = .hold
				}

				slider.ruleset.send_result(time, mut player.cursor, mut slider, slider_position, .slider_miss, combo)
			}
		}

		if !allowable && state.sliding && state.scored + state.missed < state.points.len {
			if slider.players.len == 1 {
				slider.hitslider.kill_slide(time)
			}

			state.sliding = false
		}
	}

	
	return true
}

pub fn (mut slider Slider) update_post_for(_player &DifficultyPlayer, time f64, process_slider_ends_ahead bool) bool {
	mut state := &slider.state[0]
	mut player := unsafe { &_player }

	if time > slider.hitslider.time.start + player.diff.hit50 && !state.is_start_hit {
		if slider.players.len == 1 {
			slider.hitslider.arm_start(false, time)
		}

		position := slider.hitslider.get_start_position()

		slider.ruleset.send_result(time, mut player.cursor, mut slider, position, .miss, .reset)

		if player.left_cond {
			state.down_button = left_button
		} else if player.right_cond {
			state.down_button = right_button
		} else {
			state.down_button = player.mouse_down_button
		}

		state.is_start_hit = true
		state.start_result = .miss
	}

	if (time >= slider.hitslider.time.end || (process_slider_ends_ahead && slider.hitslider.time.end - time == 1)) && !state.is_hit {
		if state.start_result != .miss {
			state.scored++
		}

		mut hit := HitResult.miss
		mut combo := ComboResult.reset
		rate := f64(state.scored) / f64(state.points.len + 1)
	
		if rate > 0 && slider.players.len == 1 {
			slider.hitslider.hit_edge(slider.hitslider.tick_reverse.len, time, true)
		}

		if rate == 1.0 {
			hit = .hit300
		} else if rate >= 0.5 {
			hit = .hit100
		} else if rate > 0.0 {
			hit = .hit50
		}

		if hit != .miss {
			combo = .hold
		}


		// // FIXME: Slider Repeat acc might be fucked rn, it keeps giving 100s
		// if hit == .miss || hit == .hit50 {
			// position := slider.hitslider.get_end_position()
			// slider.ruleset.send_result(time, mut player.cursor, mut slider, position, hit, combo)
		// }

		position := slider.hitslider.get_end_position()
		slider.ruleset.send_result(time, mut player.cursor, mut slider, position, hit, combo)

		state.is_hit = true
	}

	return state.is_hit
}

pub fn (mut slider Slider) update_post(_ f64) bool {
	mut num_finished_total := 0

	for _ in slider.players {
		mut state := &slider.state[0]

		if !state.is_hit || !state.is_start_hit {
			num_finished_total++
		}
	}

	return num_finished_total == 0
}

pub fn (slider &Slider) is_hit(player &DifficultyPlayer) bool {
	return slider.state[0].is_hit
}

pub fn (slider &Slider) is_start_hit(player &DifficultyPlayer) bool {
	return slider.state[0].is_start_hit
}

pub fn (slider &Slider) get_start_result(player &DifficultyPlayer) HitResult {
	return slider.state[0].start_result
}

pub fn (slider &Slider) get_fade_time() f64 {
	return slider.hitslider.time.start - slider.fade_start_relative
}