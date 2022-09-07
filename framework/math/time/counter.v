module time

/*
	TODO: Redesign this
*/

import math
import time as timelib 
import core.common.settings

pub const (
	update_rate_fps = settings.global.window.fps
	update_rate_ms = (f64(1000.0) / update_rate_fps) * timelib.millisecond

	global = &TimeCounter{}
)


//
pub fn get_time() &TimeCounter {
	unsafe {
		mut time := global
		return time
	}
}

fn init() {
	// Starts counting time on startup albeit with a countdown so it doesnt kill the cpu
	go fn () {
		mut time := get_time()
		for !time.stop {
			time.tick()
			timelib.sleep(update_rate_ms / 2) // Count at two time the normal speed
		}
	}()
}
//


pub struct TimeCounter {
	mut:
		start_time f64
		last_time f64

	pub mut:
		delta f64
		time  f64
		fps   f64
		speed f64 = 1.0

		// 
		stop  			 bool
		use_custom_delta bool
		custom_delta     f64
		
		//
		average f64
}

pub fn (mut t TimeCounter) stop() {
	t.stop = true
}

pub fn (mut t TimeCounter) reset() {
	t.last_time = timelib.ticks()
	t.start_time = t.last_time
	t.time = 0
	t.delta = 0
	t.fps = 0
}

pub fn (mut t TimeCounter) tick() f64 {
	now := timelib.ticks()
	
	// Most likely a recording timer, dont use system time.
	if t.use_custom_delta {
		t.delta = t.custom_delta
		t.time += t.custom_delta * t.speed

		return t.custom_delta
	} else {
		// Normal timer, use system timer.
		t.delta = now - t.last_time
		t.time = (now - t.start_time) * t.speed
		t.last_time = now
	}

	t.fps = 1000.0 / t.delta

	return t.delta
}

pub fn (mut t TimeCounter) set_speed(s f64) {
	t.speed = s
}

// New shit
// TODO: Maybe split this into its own struct?
pub fn (mut t TimeCounter) tick_average_fps() {
	delta := t.tick()

	if t.average == 0.0 {
		t.average = delta
	}

	rate := f64(1.0 - math.pow(0.1, delta / 100.0))
	t.average = t.average + (delta - t.average) * rate
}


pub fn (t &TimeCounter) get_average_fps() f64 {
	return 1000.0 / t.average
}
