module timing

const (
		ticks_per_beat = 480.0
		ticks_per_hidden = ticks_per_beat / 2.0
)

pub struct TimingPoint {
	pub mut:
		tick f64
		bpm f64
		time f64
}

pub struct Timing {
	pub mut:
		timings []TimingPoint
}

pub fn (mut timing Timing) resolve_timing(timings []TimingPoint) {
	mut time := 0.0

	for i, cur_timing in timings {
		if i > 0 {
			prev := timings[i - 1]
			time += ((cur_timing.tick - prev.tick) * 60.0) / ticks_per_beat / prev.bpm
		}

		timing.timings << TimingPoint{
			tick: cur_timing.tick,
			bpm: cur_timing.bpm,
			time: time
		}
	}
}

pub fn (mut timing Timing) to_time(tick f64) f64 {
	mut cur_timing := TimingPoint{bpm: 0xDEAD}

	for timing_to_find in timing.timings {
		if tick >= timing_to_find.tick {
			cur_timing = timing_to_find
			break
		}
	}

	if cur_timing.bpm == 0xDEAD { panic("@FUNCTION: Invalid timing") }

	return (cur_timing.time +
		((tick - cur_timing.tick) * 60.0) / ticks_per_beat / cur_timing.bpm) * 1000.0
}