module logic

// Hitsystem logic attempt 1
// Code is based/steal from danser
// thanks wieku!! :trollface:
import math

import game.beatmap
import game.beatmap.object as game_object
import game.math.difficulty

import framework.graphic.canvas
import framework.math.vector

const (
	force_hit = true
)

pub enum HitResult {
	ignore
	slidermiss
	miss
	hit50
	hit100
	hit300
}

pub enum ClickState {
	ignored
	shake
	click
}

pub struct PlayerButton {
	pub mut:
		left  bool
		right bool
}

pub struct PlayerReprensent {
	pub mut:
		position        &vector.Vector2
		difficulty 		difficulty.Difficulty 
		double_click 	bool
		already_stolen  bool
		button          PlayerButton
		game_down_state bool
		last_button     int
		last_button2    int
		left_cond       bool
		left_cond_e     bool
		right_cond      bool
		right_cond_e    bool

		//
		left_key        bool
		right_key       bool
		
		time            f64
}

pub interface HitObject {
	mut:
		logic  &StandardLogic
		is_hit bool

	init(&StandardLogic, &game_object.IHitObject, &PlayerReprensent)
	update_for(f64, bool) bool
	update_click_for(f64) bool
	update_post_for(f64) bool
	get_fade_time() f64
	get_number() int

}

pub struct StandardLogic {
	pub mut:
		beatmap   &beatmap.Beatmap
		queue     []HitObject
		processed []HitObject
		player    &PlayerReprensent
		canvas    &canvas.Canvas
}

pub fn (mut logic StandardLogic) update(time f64) {
	if logic.queue.len > 0 {
		for i := 0; i < logic.queue.len; i++ {
			if i >= logic.queue.len { println("> ${@FN}: fucked index: i=${i} - max=${logic.queue.len}") return } // ????

			mut g := &logic.queue[i]

			if g.get_fade_time() > time {
				break
			}

			logic.processed << g
			logic.queue = logic.queue[1 ..]
			// println("${logic.processed.len} ${logic.queue.len}")

			i += -1
		}
	}
}

pub fn (mut logic StandardLogic) update_normal_for(time f64, process_slider_ends_ahead bool) {
	if logic.processed.len > 0 {
		for mut hitobject in logic.processed {
			hitobject.update_for(time, process_slider_ends_ahead)
		}
	}
}

pub fn (mut logic StandardLogic) update_click_for(time f64) {
	logic.player.already_stolen = false
	is_player_or_auto := true
	
	if is_player_or_auto {
		logic.player.left_cond = !logic.player.button.left && logic.player.left_key
		logic.player.right_cond = !logic.player.button.right && logic.player.right_key

		logic.player.left_cond_e = logic.player.left_cond
		logic.player.right_cond_e = logic.player.right_cond
	}

	if logic.processed.len > 0 {
		for mut hitobject in logic.processed {
			hitobject.update_click_for(time)
		}
	}

	if is_player_or_auto {
		logic.player.button.left = logic.player.left_key
		logic.player.button.right = logic.player.right_key
	}
}

pub fn (mut logic StandardLogic) update_post_for(time f64) {
	if logic.processed.len > 0 {		
		for mut hitobject in logic.processed {
			hitobject.update_post_for(time)
		}
	}
}

pub fn (mut logic StandardLogic) can_be_hit(time f64, mut object HitObject) ClickState {
	if object is HitCircle {
		mut index := -1

		for i, mut g in logic.processed {
			if g == object {
				index = i
			}
		}

		if index > 0 && logic.beatmap.objects[logic.processed[index - 1].get_number()].stacking > 0 && !logic.processed[index - 1].is_hit {
			return .ignored
		}
	}

	for mut g in logic.processed {
		if !g.is_hit {
			if g.get_number() != g.get_number() {
				if logic.beatmap.objects[g.get_number()].time.end + 3 < logic.beatmap.objects[object.get_number()].time.start {
					return .shake
				}
			} else {
				break
			}
		}
	}

	hit_range := difficulty.hitable_range
	if math.abs(f64(time - f64(logic.beatmap.objects[object.get_number()].time.start))) >= hit_range {
		return .shake
	}

	return .click
}

pub fn (mut logic StandardLogic) initialize() {
	for mut object in logic.beatmap.objects {
		// Slider to hitcircle cuz these objects is a subtype of hitcircle
		if object is game_object.Slider {
			mut circle_logic := HitCircle{}
			circle_logic.init(logic, object.get_hit_object(), logic.player)
			logic.queue << circle_logic
		}
		else if object is game_object.Spinner {
			// panic("No")
		}
		else {
			mut circle_logic := HitCircle{}
			circle_logic.init(logic, mut object, logic.player)
			logic.queue << circle_logic
		} 
	}
}

/*
pub fn make_standard_logic(mut beatmap &beatmap.Beatmap, mut player &PlayerReprensent, time_ptr &time2.TimeCounter, mut canvas &canvas.Canvas) &StandardLogic {
	mut logic := &StandardLogic{beatmap: unsafe { beatmap }, player: unsafe { player }, canvas: unsafe { canvas }}
	logic.initialize()


	/*
	go fn (mut logic &StandardLogic, mut player &PlayerReprensent, time_ptr &time2.TimeCounter) {
		mut mutex := sync.new_mutex()
		mut input_time := &time2.TimeCounter{}
		mut max_delta := 0.0
		input_time.reset()
		
		for {
			mutex.@lock()

			logic.update_click_for(time_ptr.time)
			logic.update_normal_for(time_ptr.time, false)
			logic.update_post_for(time_ptr.time)
			logic.update(time_ptr.time)

			input_time.tick()

			if input_time.delta > max_delta {
				max_delta = input_time.delta
				println('> ${max_delta} highest delta')
			}
			
			mutex.unlock()
		}
	}(mut logic, mut player, time_ptr)
	*/

	return logic
}
*/