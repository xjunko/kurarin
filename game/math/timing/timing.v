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
		inherited f32
}

pub fn (mut tp TimingPoint) add(data []f32) {
	mut timing := TimingPointInfo{}
	timing.offset = data[0]

	if data.len < 7 || data[6] == 1 {
		timing.beatduration = data[1]
		tp.inherited = data[1]
	} else {
		timing.beatduration = f32(math.max(10.0, math.min(1000.0, data[1])) * tp.inherited / 1000)
	}

	timing.base = tp.inherited
	timing.meter = data[2]
	timing.sampleset = data[3]
	timing.sampleindex = data[4]
	timing.volume = data[5]

	tp.timings << timing
}


pub fn (mut tp TimingPoint) get_beat_duration(time f64) f32 {
	for timing in tp.timings {
		if time >= timing.offset { continue }

		return timing.beatduration
	}

	return 0
}