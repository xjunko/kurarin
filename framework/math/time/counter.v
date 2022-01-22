module time

import time as timelib // To avoid confusion (or make more)
import game.settings

pub const (
	update_rate_fps = settings.window.fps
	update_rate_ms = (f64(1000.0) / update_rate_fps) * timelib.millisecond

	global = &TimeCounter{}
)

//
pub fn get_time() &TimeCounter {
	mut time := global
	return time
}

pub fn reset() {
	// Resets global time
	mut time := get_time()
	time.reset()
}

pub fn stop() {
	mut time := get_time()
	time.stop = true
}

pub fn tick() f64 {
	mut time := get_time()
	return time.tick()
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
	pub mut:
		last  f64
		delta f64
		time  f64
		fps   f64
		speed f64 = 1.0

		// 
		stop  			 bool
		use_custom_delta bool
		custom_delta     f64
}

pub fn (mut t TimeCounter) reset() {
	t.last = timelib.ticks()
	t.time = 0
	t.delta = 0
	t.fps = 0
}

pub fn (mut t TimeCounter) tick() f64 {
	now := timelib.ticks()
	last_ticked := t.last

	t.last = now

	if t.use_custom_delta {
		t.delta = t.custom_delta
	} else {
		t.delta =  now - last_ticked
	}
	
	t.time += t.delta * t.speed
	t.fps = 1000 / t.delta

	return t.delta
}

pub fn (mut t TimeCounter) set_speed(s f64) {
	t.speed = s
}
