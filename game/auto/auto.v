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
			
			// Follow the curves 
			steps := 250
			offset := 10
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
			

			// just go to the end position
			/*
			events << ReplayEvent{
				position: object.curve.point_at(1),
				time: time.Time{object.time.start + 1, object.time.end},
			}*/

			
		} else if object is game_object.Spinner {
			distance := f64(100)
			steps := 20
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
				// println(events)
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