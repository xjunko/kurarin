module timing

import math

struct TimingPointInfo {
	pub mut:
		offset f32
		base   f32
		meter  f32
		sampleset f32
		sampleindex f32
		volume f32
		beatduration f32
}

pub struct TimingPoint {
	pub mut:
		timings   []TimingPointInfo
		data      [][]f32
		inherited f32
		
		// more info
		slider_multiplier f64
		slider_tick_rate  f64
}

pub fn (mut tp TimingPoint) add_line(data []f32) {
	tp.data << data
}

pub fn (mut tp TimingPoint) add(data []f32) {
	tp.add_line(data)
}

pub fn (mut tp TimingPoint) process() {
	mut inherited := f32(0)

	for items in tp.data {
		mut timing := TimingPointInfo{}

		timing.offset = items[0]

		if items.len < 7 || items[6] == 1.0 {
			timing.beatduration = items[1]
			inherited = timing.beatduration
		} else {
			timing.beatduration = f32(
				math.max(10.0, math.min(1000.0, -items[1])) * inherited / 100
			)
		}

		timing.base = inherited
		timing.meter = items[2]
		timing.sampleset = items[3]
		timing.sampleindex = items[4]
		timing.volume = items[5]

		tp.timings << timing
	}

	unsafe {
		tp.data.free()
	}
}


pub fn (mut tp TimingPoint) get_point_at(time f64) TimingPointInfo {
	// its 3am rn and my brain is not working
	// this is stupid but i cant think of better idea to do this
	mut last_highest := &TimingPointInfo{}

	for i := tp.timings.len - 1; i >= 0; i-- {
		if time >= tp.timings[i].offset { last_highest = &tp.timings[i] break }
		last_highest = &tp.timings[i]
	}
	
	return *last_highest
}

pub fn (mut tp TimingPoint) get_beat_duration(time f64) f32 {
	return tp.get_point_at(time).beatduration
}

pub fn (tp TimingPoint) get_scoring_distance() f64 {
	return (100.0 * tp.slider_multiplier) / tp.slider_tick_rate
}

pub fn (tp TimingPoint) get_velocity(point TimingPointInfo) f64 {
	mut velocity := tp.get_scoring_distance() * tp.slider_tick_rate
	beatduration := point.beatduration

	if beatduration >= 0 {
		velocity *= 1000.0 / beatduration
	}

	return velocity
}

pub fn (tp TimingPoint) get_slider_time(pixel_length f64, point TimingPointInfo) f64 {
	return point.beatduration * pixel_length / (100.0 * tp.slider_multiplier)
}