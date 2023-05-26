module movers

import math
import framework.math.vector
import framework.math.easing
import core.osu.beatmap.object

pub struct HalfCircleMover {
	Mover
pub mut:
	middle vector.Vector2[f64]
	radius f64
	ang    f64
}

pub fn (mut halfcircle HalfCircleMover) init(mut start object.IHitObject, mut end object.IHitObject, direction int) {
	halfcircle.Mover.init(mut start, mut end, direction)
	halfcircle.middle.x = (halfcircle.start.x + halfcircle.end.x) / 2.0
	halfcircle.middle.y = (halfcircle.start.y + halfcircle.end.y) / 2.0
	halfcircle.radius = halfcircle.middle.distance(halfcircle.start)
	halfcircle.ang = math.atan2(halfcircle.start.y - halfcircle.middle.y, halfcircle.start.x - halfcircle.middle.x)
}

pub fn (mut halfcircle HalfCircleMover) get_point_at(time f64) vector.Vector2[f64] {
	ang := halfcircle.ang + math.pi * halfcircle.get_multiplier(time) * halfcircle.direction
	return vector.Vector2[f64]{halfcircle.middle.x + math.cos(ang) * halfcircle.radius,
		halfcircle.middle.y + math.sin(ang) * halfcircle.radius}
}

pub fn (halfcircle &HalfCircleMover) get_multiplier(time f64) f64 {
	return easing.quad_out(time - halfcircle.time.start, 0, 1.0, halfcircle.time.duration())
}
