module players

// import sync
import math
import lib.gg

import game.logic
import game.beatmap
import game.beatmap.object as game_object

import framework.math.time
import framework.math.easing
import framework.math.vector
import framework.graphic.sprite
import framework.graphic.canvas

// import parser
import structs { ReplayKeys, ReplayEvent }

pub interface IPlayer {
	mut:
		sprite &sprite.Sprite
		player &logic.PlayerReprensent
		logic  &logic.StandardLogic
		events []ReplayEvent

	update(f64)
}

pub struct AutoPlayer {
	pub mut:
		sprite &sprite.Sprite = &sprite.Sprite{always_visible: true}
		player &logic.PlayerReprensent
		logic  &logic.StandardLogic
		events []ReplayEvent
		event_i int
		keys   ReplayKeys
}

pub fn (mut auto AutoPlayer) update(time f64) {
	// // do some keys shit
	// if auto.event_i < auto.events.len {
	// 	if time >= auto.events[auto.event_i].time.start {
	// 		if auto.events[auto.event_i].keys.k1 {
	// 			auto.player.left_key = true
	// 		}
			

	// 		// stop 
	// 		if time >= auto.events[auto.event_i].time.end + 32 {
	// 			auto.player.left_key = false
	// 			auto.event_i += 1
	// 		}
	// 	}
	// }
		
	// auto.logic.update_click_for(time)
	// auto.logic.update_normal_for(time, false)
	// auto.logic.update_post_for(time)
	// auto.logic.update(time)
}


pub fn make_auto(beatmap beatmap.Beatmap, mut canvas canvas.Canvas, mut game_time &time.TimeCounter) &AutoPlayer {
	mut auto := &AutoPlayer{player: 0, logic: 0}
	auto.player = &logic.PlayerReprensent{position: auto.sprite.position, difficulty: beatmap.difficulty_math}
	auto.logic = &logic.StandardLogic{
		beatmap: &beatmap,
		player: unsafe { auto.player },
		canvas: unsafe { canvas }
	}
	auto.sprite.textures << gg.get_texture_from_skin('cursor')
	auto.logic.initialize()
	
	// cursor size relative to circle size
	auto.sprite.add_transform(typ: .scale_factor, time: time.Time{0,0}, before: [f64(1.0-0.7*(1.0 + beatmap.difficulty_math.cs - 5)/5)])


	mut prev_object := beatmap.objects[0]
	mut last_position := prev_object.position
	for object in beatmap.objects {
		if object is game_object.Slider {
			auto.events << ReplayEvent{
				position: object.position,
				time: time.Time{object.time.start, object.time.end},
				keys: ReplayKeys{k1: true}
			}

			//
			auto.sprite.add_transform(typ: .move, easing: easing.quad_out, time: time.Time{prev_object.time.end, object.time.start}, before: [prev_object.end_position.x, prev_object.end_position.y], after: [object.position.x, object.position.y])

			// Use curve
			offset := 16
			last_position = object.position
			for temp_time := int(object.time.start); temp_time <= int(object.time.end); temp_time += offset {
				times := int(((temp_time - object.time.start) / object.duration) + 1)
				t_time := (f64(temp_time) - object.time.start - (times - 1) * object.duration)
				rt := object.pixel_length / object.curve.length

				mut pos := vector.Vector2{}
				if (times % 2) == 1 {
					pos = object.curve.point_at(rt * t_time / object.duration)
				} else {
					pos = object.curve.point_at((1.0 - t_time / object.duration) * rt)
				}
				auto.sprite.add_transform(typ: .move, time: time.Time{temp_time, temp_time + offset}, before: [last_position.x, last_position.y], after: [pos.x, pos.y])
				last_position = pos
			}
		} else if object is game_object.Spinner {
			speed := f64(0.85)
			timeframe := f64(16)
			// mut radius := math.sin(object.time.start)
			radius := 50
			mut rot := f64(0)

			// last_position = vector.Vector2{
			// 	math.cos(rot) * radius + 512 / 2,
			// 	math.sin(rot) * radius + 384 / 2
			// }
			for i := object.time.start; i < object.time.end; i += timeframe {
				// radius = 10 + math.sin(i / 60) * 5.33 * 50 // lmao
				position := vector.Vector2{
					math.cos(rot) * radius + 512 / 2,
					math.sin(rot) * radius + 384 / 2
				}

				auto.sprite.add_transform(typ: .move, easing: easing.linear, time: time.Time{i, i + timeframe}, before: [last_position.x, last_position.y], after: [position.x, position.y])

				rot += speed
				last_position = position
			}
		} else {
			auto.events << ReplayEvent{
				position: object.position,
				time: time.Time{object.time.start, object.time.start},
				keys: ReplayKeys{k1: true}
			}

			auto.sprite.add_transform(typ: .move, easing: easing.quad_out, time: time.Time{prev_object.time.end, object.time.start}, before: [last_position.x, last_position.y], after: [object.position.x, object.position.y])
			last_position = object.position
		}
		prev_object = object // uhhhhhh ok v
	}

	// Replay file test
	// replay := parser.parse_replay("assets/replay/shiori.osr") or {panic(err)}
	// auto.events << replay.events
	// auto.reset_movement_based_on_replay()

	// 
	auto.sprite.after_add_transform_reset()
	canvas.add_drawable(auto.sprite)


	return auto
}

// V doesnt have a way to point to a struct's function yet