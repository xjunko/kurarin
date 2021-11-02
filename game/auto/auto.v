module auto

import game.beatmap
import framework.math.time
import framework.math.vector

pub struct ReplayEvent {
	pub mut:
		position vector.Vector2
		time      time.Time
}

// bruh
pub fn make_auto(bmap beatmap.Beatmap) []ReplayEvent {
	mut events := []ReplayEvent{}
	
	for object in bmap.objects {
		events << ReplayEvent{
			position: object.position,
			time: time.Time{object.time.start, object.time.end}
		}
	}

	events.sort(a.time.start < b.time.start)
	
	return events
}