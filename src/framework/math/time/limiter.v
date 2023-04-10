module time

import time as timelib
import math

/*
Reference:
	https://github.com/Wieku/danser-go/blob/10faa98060a2dca369ff2aaf49e18496c8f4a008/framework/frame/limiter.go#L26
*/

pub struct Limiter {
pub mut:
	fps                 int
	variable_yield_time i64
	last_time           i64
}

pub fn (mut limiter Limiter) sync() {
	if limiter.fps <= 0 {
		return
	}

	sleep_time := i64(1000000000) / limiter.fps
	yield_time := math.min[i64](sleep_time, limiter.variable_yield_time +
		sleep_time % i64(1000 * 1000))
	mut over_sleep := i64(0)

	for {
		t := i64(timelib.sys_mono_now()) - limiter.last_time

		if t < sleep_time - yield_time {
			timelib.sleep(1 * timelib.millisecond)
		} else if t < sleep_time {
			// Do anything to slow down one cycle
			timelib.sleep(timelib.nanosecond) // lol
		} else {
			over_sleep = t - sleep_time
			break
		}
	}

	limiter.last_time = i64(timelib.sys_mono_now()) - math.min[i64](over_sleep, sleep_time)

	if over_sleep > limiter.variable_yield_time {
		limiter.variable_yield_time = math.min[i64](limiter.variable_yield_time + 200 * 1000,
			sleep_time)
	} else if over_sleep < limiter.variable_yield_time - 200 * 1000 {
		limiter.variable_yield_time = math.min[i64](limiter.variable_yield_time - 2 * 1000,
			0)
	}
}
