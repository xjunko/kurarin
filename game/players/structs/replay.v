module structs


import framework.math.vector
import framework.math.time

pub struct ReplayKeys {
	pub mut:
		k1 bool
		k2 bool
		m1 bool
		m2 bool
		smoke bool
}

pub struct ReplayEvent {
	pub mut:
		position vector.Vector2
		time      time.Time
		keys      ReplayKeys
}