module time

import time as timelib
import core.common.settings

pub const update_rate_fps = settings.global.window.fps
pub const update_rate_ms = (f64(1000.0) / update_rate_fps) * timelib.millisecond

// vfmt off
// HACK: vfmt fucks up here...
__global (
	time_counter = &TimeCounter{}
)
// vfmt on

@[inline]
pub fn get_time() &TimeCounter {
	return time_counter
}

pub struct TimeCounter {
mut:
	start_time f64
	last_time  f64
	offset     f64
pub mut:
	delta f64
	time  f64
	fps   f64
	speed f64 = 1.0
	//
	stop             bool
	use_custom_delta bool
	custom_delta     f64
}

pub fn (mut t TimeCounter) stop() {
	t.stop = true
}

@[args; params]
pub struct ResetArgs {
pub:
	offset f64
}

pub fn (mut t TimeCounter) reset(arg ResetArgs) {
	t.offset = arg.offset
	t.last_time = f64(timelib.ticks())
	t.start_time = t.last_time
	t.time = 0
	t.delta = 0
	t.fps = 0
}

pub fn (mut t TimeCounter) tick() f64 {
	now := f64(timelib.ticks())

	// Most likely a recording timer, dont use system time.
	if t.use_custom_delta {
		t.delta = t.custom_delta
		t.time += (t.custom_delta * t.speed) - t.offset

		return t.custom_delta
	} else {
		// Normal timer, use system timer.
		t.delta = now - t.last_time
		t.time = ((now - t.start_time) * t.speed) - t.offset
		t.last_time = now
	}

	t.fps = 1000.0 / t.delta

	return t.delta
}

pub fn (mut t TimeCounter) set_speed(s f64) {
	t.speed = s
}

fn init() {
	spawn fn () {
		for !time_counter.stop {
			time_counter.tick()
			timelib.sleep(update_rate_ms / 2) // tick at double the delta
		}
	}()
}
