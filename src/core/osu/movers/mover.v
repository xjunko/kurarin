/*
Totally not copied from opsu-dance

	https://github.com/yugecin/opsu-dance/blob/7b2c0efa514bbdb15ae332963e277805cc83810c/src/yugecin/opsudance/movers/Mover.java#L1
*/

module movers

import framework.math.vector
import framework.math.time
import core.osu.beatmap.object

pub struct Mover {
pub mut:
	start     vector.Vector2
	end       vector.Vector2
	time      time.Time
	direction int
}

pub fn (mut mover Mover) init(mut start object.IHitObject, mut end object.IHitObject, direction int) {
	// This will be inherited by other movers
	mover.direction = direction
	mover.start = start.get_end_position()
	mover.end = end.get_start_position()
	mover.time.start = start.get_end_time()
	mover.time.end = end.get_start_time()
}

pub fn (mover &Mover) get_multiplier(update_time f64) f64 {
	return (update_time - mover.time.start) / mover.time.duration()
}

pub fn (mut mover Mover) get_point_at(update_time f64) vector.Vector2 {
	panic('Not implemented!')
}

// INterface
pub interface IMover {
mut:
	start vector.Vector2
	end vector.Vector2
	time time.Time
	init(mut start object.IHitObject, mut end object.IHitObject, direction int)
	get_multiplier(time f64) f64
	get_point_at(time f64) vector.Vector2
}

pub fn get_imover() &IMover {
	return &LinearMover{}
}
