module auto

import framework.math.vector
import framework.math.time

pub struct ReplayEvent {
	pub mut:
		position vector.Vector2
		time      time.Time
		key       int 
}