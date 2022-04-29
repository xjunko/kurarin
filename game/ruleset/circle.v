module ruleset

import math
import game.beatmap.object
// import game.beatmap.difficulty

pub struct ObjectState {
	pub mut:
		is_hit bool
}

pub struct Circle {
	pub mut:
		ruleset &Ruleset = voidptr(0)
		hitcircle &object.Circle = voidptr(0)
		players []&DifficultyPlayer
		state []ObjectState
		fade_start_relative f64
}

pub fn (circle &Circle) get_number() i64 {
	return circle.hitcircle.get_id()
}

pub fn (mut circle Circle) init(ruleset &Ruleset, object object.IHitObject, players []&DifficultyPlayer) {
	circle.ruleset = unsafe { ruleset }
	circle.players = players
	circle.state = []ObjectState{}
	
	mut t_object := unsafe { &object }
	if mut t_object is object.Circle {
		circle.hitcircle = t_object
	}

	circle.fade_start_relative = 1000000.0

	for player in circle.players {
		circle.state << &ObjectState{}
		circle.fade_start_relative = math.min<f64>(circle.fade_start_relative, player.diff.preempt)
	}
}

pub fn (mut circle Circle) update_for(_ &DifficultyPlayer, time f64, _ bool) bool {
	return true
}

pub fn (mut circle Circle) update_click_for(_player &DifficultyPlayer, time f64) bool {
	mut state := &circle.state[0]
	mut player := unsafe { &_player }

	if !state.is_hit {
		position := circle.hitcircle.position

		clicked := player.left_cond_e || player.right_cond_e

		mut radius := player.diff.circle_radius

		// TODO: Relax
		if false {
			radius = 100.0
		}

		in_range := player.cursor.position.distance(position) <= radius


		if clicked {	
			action := circle.ruleset.can_be_hit(time, mut circle, player)
			
			if in_range {
				if action == .click {
					if player.left_cond_e {
						player.left_cond_e = false
					} else if player.right_cond_e {
						player.right_cond_e = false
					}

					mut hit := HitResult.miss

					relative := math.abs<f64>(time - circle.hitcircle.get_end_time())

					if relative < player.diff.hit300 {
						hit = .hit300
					} else if relative < player.diff.hit100 {
						hit = .hit100
					} else if relative < player.diff.hit50 {
						hit = .hit50
					}

					if hit != .ignore {
						mut combo := ComboResult.increase

						if hit == .miss {
							combo = .reset
						} else {
							if circle.players.len == 1 {
								circle.hitcircle.play_hitsound()
							}
						}

						if circle.players.len == 1 {
							circle.hitcircle.arm(hit != .miss, time)
						}

						circle.ruleset.send_result(time, mut player.cursor, mut circle, position, hit, combo)

						state.is_hit = true
					}
				} else {
					player.left_cond_e = false
					player.right_cond_e = false

					if action == .shake && circle.players.len == 1 {
						circle.hitcircle.shake(time)
						// panic("CIRCLE SHAKE")
					}
				}
			} else if action == .click {
				// circle.ruleset.send_result(time, mut player.cursor, mut circle, position, .miss)
			}
		}
	}

	return !state.is_hit
}

pub fn (mut circle Circle) update_post_for(_player &DifficultyPlayer, time f64, _ bool) bool {
	mut state := &circle.state[0]
	mut player := unsafe { &_player }

	if time > circle.hitcircle.get_end_time() + player.diff.hit50 && !state.is_hit {
		position := circle.hitcircle.position
		circle.ruleset.send_result(time, mut player.cursor, mut circle, position, .miss, .reset)

		if circle.players.len == 1 {
			circle.hitcircle.arm(false, time)
		}

		state.is_hit = true
	}
	
	return state.is_hit
}

pub fn (mut circle Circle) update_post(_ f64) bool {
	mut unfinished := 0

	for i, _ in circle.players {
		state := &circle.state[i]

		if !state.is_hit {
			unfinished++
		}
	}

	return unfinished == 0
}

pub fn (mut circle Circle) is_hit(player &DifficultyPlayer) bool {
	return circle.state[0].is_hit
}

pub fn (mut circle Circle) get_fade_time() f64 {
	return circle.hitcircle.get_start_time() - circle.fade_start_relative
}