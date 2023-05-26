module camera

import framework.math.vector

pub struct Camera {
pub mut:
	offset vector.Vector2[f64]
	scale  f64 = f64(1.0)
}

pub fn (camera &Camera) translate(position vector.Vector2[f64]) vector.Vector2[f64] {
	return position.scale(camera.scale).add(camera.offset)
}
