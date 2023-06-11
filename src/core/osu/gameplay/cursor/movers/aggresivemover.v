module movers

import math
import framework.math.easing
import framework.math.vector
import core.osu.parsers.beatmap.object
import core.osu.parsers.beatmap.object.curves

// Reimplentation (literally copy-pasted 8) ) based on
// https://github.com/Wieku/danser-go/blob/master/app/dance/movers/aggressive.go
pub struct AggressiveMover {
	Mover
pub mut:
	line       &curves.Bezier = unsafe { nil }
	last_angle f64
}

pub fn (mut aggressive AggressiveMover) init(mut start object.IHitObject, mut end object.IHitObject, direction int) {
	aggressive.Mover.init(mut &start, mut &end, direction)

	start_pos := start.get_end_position()
	end_pos := end.get_start_position()
	scaled_distance := aggressive.time.duration()

	mut new_angle := aggressive.last_angle + math.pi

	if mut start is object.Slider {
		new_angle = start.get_end_angle()
	}

	mut points := []vector.Vector2[f64]{}
	points << [
		start_pos,
		vector.new_vec_rad(new_angle, scaled_distance).add(start_pos),
	]

	if scaled_distance > 1 {
		aggressive.last_angle = points[1].angle_rv(end_pos)
	}

	if mut end is object.Slider {
		points << vector.new_vec_rad(end.get_start_angle(), scaled_distance).add(end_pos)
	}

	points << end_pos

	aggressive.line = curves.make_bezier(points)
}

pub fn (aggressive &AggressiveMover) get_point_at(time f64) vector.Vector2[f64] {
	if aggressive.line == unsafe { nil } {
		return aggressive.start
	}

	return aggressive.line.point_at(aggressive.get_multiplier(time))
}

pub fn (aggressive &AggressiveMover) get_multiplier(time f64) f64 {
	return easing.linear(time - aggressive.time.start, 0, 1.0, aggressive.time.duration())
}
