module auto

import math

import game.beatmap
import game.beatmap.object as game_object
import framework.math.time
import framework.math.vector

pub struct ReplayEvent {
	pub mut:
		position vector.Vector2
		time      time.Time
		key       int 
}

// bruh
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