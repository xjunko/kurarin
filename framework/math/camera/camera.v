module camera

import framework.math.vector

pub struct Camera {
	pub mut:
		offset vector.Vector2
		scale  f64 = f64(1.0)
}