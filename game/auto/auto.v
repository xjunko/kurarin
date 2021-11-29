module auto

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
}

pub fn (mut auto AutoPlayer) update(time f64) {
	// do some keys shit
	if auto.event_i < auto.events.len {
		if time >= auto.events[auto.event_i].time.start {
			if auto.events[auto.event_i].key != 0 {
				auto.player.left_key = true
			}

			// stop 
			if time >= auto.events[auto.event_i].time.start + 32 {
				auto.player.left_key = false
				auto.event_i += 1
			}
		}
	}

	auto.logic.update_click_for(time)
	auto.logic.update_normal_for(time, false)
	auto.logic.update_post_for(time)
	auto.logic.update(time)
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
	for object in beatmap.objects {
		if object is game_object.Slider {
			auto.events << ReplayEvent{
				position: object.position,
				time: time.Time{object.time.start, object.time.start},
				key: 1 << 1
			}

			//
			auto.sprite.add_transform(typ: .move, time: time.Time{prev_object.time.end, object.time.start}, before: [prev_object.end_position.x, prev_object.end_position.y], after: [object.position.x, object.position.y])

			// Use curve
			offset := 16
			mut last_position := object.position
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
			// speed := f64(0.85)
			// radius := f64(50)
			// timeframe := f64(16)
			// mut rot := f64(0)

			// mut last_position := vector.Vector2{
			// 	math.cos(rot) * radius + 512 / 2,
			// 	math.sin(rot) * radius + 384 / 2
			// }
			// for i := object.time.start; i < object.time.end; i += timeframe {
			// 	position := vector.Vector2{
			// 		math.cos(rot) * radius + 512 / 2,
			// 		math.sin(rot) * radius + 384 / 2
			// 	}

			// 	auto.sprite.add_transform(typ: .move, easing: easing.linear, time: time.Time{object.time.start + i, object.time.start + timeframe + i}, before: [last_position.x, last_position.y], after: [position.x, position.y])

			// 	rot += speed
			// 	last_position = position
			// }
		} else {
			auto.events << ReplayEvent{
				position: object.position,
				time: time.Time{object.time.start, object.time.start},
				key: 1 << 1
			}

			auto.sprite.add_transform(typ: .move, easing: easing.quad_out, time: time.Time{prev_object.time.end, object.time.start}, before: [prev_object.end_position.x, prev_object.end_position.y], after: [object.position.x, object.position.y])
		}
		prev_object = object // uhhhhhh ok v
	}

	// 
	auto.sprite.after_add_transform_reset()
	canvas.add_drawable(auto.sprite)


	// update loop
	/*
	go fn (mut auto AutoPlayer, game_time &time.TimeCounter) {
		for {
			auto.update(game_time.time)
		}
	}(mut auto, game_time)
	*/

	return auto
}

// bruh
/*
pub fn make_auto(bmap beatmap.Beatmap) []ReplayEvent {
	mut events := []ReplayEvent{}
	
	for object in bmap.objects {
		if object is game_object.Slider {
			events << ReplayEvent{
				position: object.position,
				time: time.Time{object.time.start, object.time.start},
				key: 1 << 1
			}
			

			// attr
			steps := 100
			offset := 10
			
			// Follow the curves 
			if object.points.len != 0 {
				for i in 0 .. 1000 {
					if (i % steps) == 0 {
						// Get slider points
						// position := object.curve.point_at(f64(i) / f64(1000))
						position := object.points[int(math.min(int(object.points.len * (f64(i) / f64(1000))), object.points.len))]
						time_offset := (object.time.end - object.time.start - offset) * (f64(i) / f64(1000))

						events << ReplayEvent{
							position: position,
							time: time.Time{object.time.start + offset + time_offset, object.time.start + offset + time_offset},
						}
					}
				}

				// Free points
				unsafe {
					object.points.free()
				}
			} else {
				// HACKHACHACK: DUPLICAT CODE!!!!
				// Assuming curves is valid so lets use that instead
				for i in 0 .. 1000 {
					if (i % steps) == 0 {
						position := object.curve.point_at(f64(i) / f64(1000))
						time_offset := (object.time.end - object.time.start - offset) * (f64(i) / f64(1000))

						events << ReplayEvent{
							position: position,
							time: time.Time{object.time.start + offset + time_offset, object.time.start + offset + time_offset},
						}
					}
				}
			}

			
			

			// just go to the end position
			/*
			events << ReplayEvent{
				position: object.curve.point_at(1),
				time: time.Time{object.time.start + 1, object.time.end},
			}*/

			
		} else if object is game_object.Spinner {
			/*
			distance := f64(100)
			steps := 1
			for i := 0; i < 1000; i += steps {
				progress := (object.time.end - object.time.start) * (f64(i) / f64(1000))

				position := vector.Vector2{
					x: 256 + math.sin(i) * distance,
					y: 192 + math.cos(i) * distance,
				}

				events << ReplayEvent{
					position: position,
					time: time.Time{object.time.start + progress, object.time.start + progress + steps}
				}
			}
			*/
			speed := f64(0.85)
			radius := f64(50)
			timeframe := f64(16)
			mut rot := f64(0)

			for i := object.time.start; i < object.time.end; i += timeframe {
				pos_x := math.cos(rot) * radius + 512 / 2
				pos_y := math.sin(rot) * radius + 384 / 2

				events << ReplayEvent{
					position: vector.Vector2{pos_x, pos_y},
					time: time.Time{i, i}
				}

				rot += speed
			}
			
		} else {
			events << ReplayEvent{
				position: object.position,
				time: time.Time{object.time.start, object.time.start},
				key: 1 << 1
			}
		}
	}

	events.sort(a.time.start < b.time.start)
	
	return events
}
*/