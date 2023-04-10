module camera

import framework.math.vector

pub struct Camera {
pub mut:
	offset vector.Vector2
	scale  f64 = f64(1.0)
}

pub fn (camera &Camera) translate(position vector.Vector2) vector.Vector2 {
	return position.scale(camera.scale).add(camera.offset)
}
