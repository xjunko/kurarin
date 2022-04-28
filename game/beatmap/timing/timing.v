module timing

import math

pub struct TimingPoint {
	pub mut:
		time f64

		beatlengthbase f64
		beatlength f64

		sample_set int
		sample_index int
		sample_volume f64

		signature int

		inherited bool

		kiai bool
}

fn get_default_timing() TimingPoint {
	return TimingPoint{
		time: 0.0,
		beatlengthbase: 60000.0 / 60.0,
		beatlength: 60000.0 / 60.0,
		sample_set: 0,
		sample_index: 1,
		sample_volume: 1,
		signature: 4,
		inherited: false,
		kiai: false,
	}
}

pub fn (t &TimingPoint) get_ratio() f64 {
	if t.beatlength >= 0.0 || math.is_nan(t.beatlength) {
		return 1.0
	}

	return f64(
		f32(
			math.clamp(-t.beatlength, 10, 1000)
		) / 100
	)
}

pub fn (t &TimingPoint) get_base_beat_length() f64 {
	return t.beatlengthbase
}

pub fn (t &TimingPoint) get_beat_length() f64 {
	return t.beatlengthbase * t.get_ratio()
}

pub struct Timings {
	pub mut:
		slider_multiplier f64
		slider_tick_rate  f64

		default_timing_point TimingPoint = get_default_timing()

		points          []TimingPoint
		original_points []TimingPoint

		base_set int =  1
		last_set int
}

pub fn (mut timing Timings) add_point(time f64, beatlength f64, sample_set int, sample_index int, sample_volume f64, signature int, inherited bool, kiai bool) {
	timing.points << TimingPoint{
		time: time,
		beatlengthbase: beatlength,
		beatlength: beatlength,
		sample_set: sample_set,
		sample_index: sample_index,
		sample_volume: sample_volume,
		signature: signature,
		inherited: inherited,
		kiai: kiai
	}
}

pub fn (mut timing Timings) calculate() {
	timing.points.sort(a.time < b.time)

	for i, mut point in timing.points {
		if point.inherited && i > 0 {
			last_point := timing.points[i - 1]
			point.beatlengthbase = last_point.beatlengthbase
			timing.points[i] = point
		} else {
			timing.original_points << point
		}
	}
}

pub fn (timing &Timings) get_point_at(time f64) TimingPoint {
	mut i := 0

	for point in timing.points {
		if time < point.time {
			break
		}
		i++
	}

	return timing.points[int(math.max(i-1, 0))]
}

pub fn (timing &Timings) get_slider_time_part(point TimingPoint, pixel_length f64) f64 {
	return f64(f32(1000.0*pixel_length) / f32(100.0*timing.slider_multiplier*(1000.0/point.get_beat_length())))
}

pub fn (timing &Timings) get_scoring_distance() f64 {
	return (100.0 * timing.slider_multiplier) / timing.slider_tick_rate
}

pub fn (timing &Timings) get_tick_distance(point TimingPoint) f64 {
	return timing.get_scoring_distance() / point.get_ratio()
}

pub fn (timing &Timings) get_velocity(point TimingPoint) f64 {
	mut velocity := timing.get_scoring_distance() * timing.slider_tick_rate

	beat_length := point.get_beat_length()

	if beat_length >= 0 {
		velocity *= 1000.0 / beat_length
	}

	return velocity
}