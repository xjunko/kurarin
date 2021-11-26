module logic

import math
import game.beatmap.object
import framework.math.time
import framework.math.vector


pub struct HitCircle {
	pub mut:
		logic     &StandardLogic = voidptr(0)
		circle    &object.HitObject = voidptr(0)
		player    &PlayerReprensent = voidptr(0)
		fade_time f64
		is_hit    bool

		//
		global_position vector.Vector2

}

pub fn (mut hitcircle HitCircle) init(logic &StandardLogic, circle &object.IHitObject, player &PlayerReprensent) {
	unsafe {
		hitcircle.logic = logic
		hitcircle.player = player

		if circle is object.HitObject {
			hitcircle.circle = circle
		} else if circle is object.Slider {
			hitcircle.circle = &circle.HitObject
		}
	}

	hitcircle.fade_time = f64(1000000)
	hitcircle.fade_time = f64(math.min(
		hitcircle.fade_time, player.difficulty.preempt
	))

	// HACK: TEMP
	// hitcircle.fade_time += f64(300)

	hitcircle.init_old()
}

pub fn (mut hitcircle HitCircle) update_for(time f64, _ bool) bool {
	// HACK: remove this or put it somewhere else
	
	if time >= hitcircle.circle.time.start && !hitcircle.is_hit && force_hit {
		hitcircle.circle.arm(true, time)
		hitcircle.is_hit = true
	}
	
	
	return true
}

pub fn (mut hitcircle HitCircle) init_old() {
	// PlayerMode
	// convert hitcircle position to global
	// size := vector.Vector2{hitcircle.player.difficulty.circleradius, hitcircle.player.difficulty.circleradius}.scale_(hitcircle.logic.canvas.scale)
	// origin := size.scale_origin_(vector.centre)
	// position := hitcircle.circle.position.scale_(hitcircle.logic.canvas.scale).sub_(origin).add_(hitcircle.logic.canvas.position.scale_(hitcircle.logic.canvas.scale))
	// hitcircle.global_position = position
}

pub fn (mut hitcircle HitCircle) update_click_for(time f64) bool {
	if force_hit { return true } // ignore hitsystem

	if !hitcircle.is_hit {
		clicked := hitcircle.player.left_cond_e || hitcircle.player.right_cond_e
		radius := hitcircle.player.difficulty.circleradius

		in_range := hitcircle.player.position.distance(hitcircle.circle.position) <= radius
		// in_range := hitcircle.player.position.distance(hitcircle.global_position) <= radius // PlayerMode
		if clicked {
			action := hitcircle.logic.can_be_hit(time, mut hitcircle)
			if in_range {
				if action == .click {
					if hitcircle.player.left_cond_e {
						hitcircle.player.left_cond_e = false
					} else if hitcircle.player.right_cond_e {
						hitcircle.player.right_cond_e = false
					}

					mut hit := HitResult.miss
					relative := f64(math.abs(time - hitcircle.circle.time.end))

					if relative < hitcircle.player.difficulty.hit300 {
						hit = .hit300
					} else if relative < hitcircle.player.difficulty.hit100 {
						hit = .hit100
					} else if relative < hitcircle.player.difficulty.hit50 {
						hit = .hit50
					}

					if hit != .ignore {
						hitcircle.circle.arm(hit != .miss, time)
						hitcircle.is_hit = true
					}
				} else {
					hitcircle.player.left_cond_e = false
					hitcircle.player.right_cond_e = false

					if action == .shake {
						hitcircle.circle.shake(time)
					}
				}
			}
		}
	}

	return !hitcircle.is_hit
}

pub fn (mut hitcircle HitCircle) update_post_for(time f64) bool {
	if time >= hitcircle.circle.time.end + hitcircle.player.difficulty.hit50 && !hitcircle.is_hit {
		hitcircle.circle.arm(false, time)

		hitcircle.is_hit = true
	}

	return hitcircle.is_hit
}

pub fn (hitcircle HitCircle) get_fade_time() f64 {
	return f64(
		hitcircle.circle.time.start - hitcircle.fade_time
	)
}

pub fn (hitcircle HitCircle) get_number() int {
	return hitcircle.circle.id
}