module cursor

import math
import library.gg

import game.beatmap.object
import game.movers

pub struct AutoCursor {
	pub mut:
		cursor  &Cursor
		mover   &movers.LinearMover = &movers.LinearMover{}
		queue   []object.IHitObject
		queue_i int

		// Keys logic
		last_time f64
		previous_end f64
		release_left_at f64 = -123456
		release_right_at f64 = -123456
		was_right_before bool
}

pub fn (mut auto AutoCursor) update(time f64) {
	// Normal cursor shit
	auto.cursor.update(time)

	// Auto
	// Looks abit janky compared to the pregenerated one.
	if auto.queue_i < auto.queue.len {
		mut current_object := &auto.queue[auto.queue_i]
		if auto.last_time < current_object.get_start_time() && time >= current_object.get_start_time() {
			// Update keys
			start_time := current_object.get_start_time()
			end_time := current_object.get_end_time()

			mut release_at := end_time + 50.0

			if auto.queue_i + 1 < auto.queue.len {
				n_time := auto.queue[math.min<int>(auto.queue_i + 2, auto.queue.len - 1)].get_start_time()
				release_at = math.clamp(n_time - 2.0, end_time + 1.0, release_at)
			}

			should_be_right := !auto.was_right_before && start_time - auto.previous_end < 140.0

			if should_be_right {
				auto.release_right_at = release_at
			} else {
				auto.release_left_at = release_at
			}

			auto.was_right_before = should_be_right
			auto.previous_end = end_time
		}

		if auto.queue[auto.queue_i].time.start <= time {
			if time > auto.queue[auto.queue_i].time.end {
				auto.queue_i++
				if auto.queue_i + 1 < auto.queue.len {
					auto.mover.init(
						mut &auto.queue[auto.queue_i - 1], 
						mut &auto.queue[auto.queue_i],
						1
					)
				} else {
					auto.queue_i = auto.queue.len - 1
					auto.cursor.left_button = false
					auto.cursor.right_button = false
					return // We're done here.
				}
			}
		}

		mover_time := time - auto.mover.time.start
		// Apply the position
		if mover_time >= 0.0 {
			// HitCircle mover
			if time <= auto.mover.time.end {
				pos := auto.mover.get_point_at(time)
				auto.cursor.position.x = pos.x
				auto.cursor.position.y = pos.y
			}

			// Bit of an hack cuz we dont want to calculate slider path on update (we can but i dont want to so...)
			// Slider mover
			mut cur_hitobject := &auto.queue[auto.queue_i]
			if (time >= auto.mover.time.end && time <= cur_hitobject.time.end) && mut cur_hitobject is object.Slider {
				auto.cursor.position.x = cur_hitobject.slider_b_sprite.position.x	
				auto.cursor.position.y = cur_hitobject.slider_b_sprite.position.y
			}
		}
	}

	auto.cursor.left_button = time < auto.release_left_at
	auto.cursor.right_button = time < auto.release_right_at
	auto.last_time = time
}

pub fn make_auto_cursor(mut ctx &gg.Context, hitobjects []object.IHitObject) &AutoCursor {
	mut auto := &AutoCursor{
		cursor: make_cursor(mut ctx),
		queue: hitobjects
	}

	return auto
}