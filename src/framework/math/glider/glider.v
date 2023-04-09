module glider

import framework.math.time
import framework.math.easing

pub struct Event {
pub mut:
	time            time.Time
	target_value    f64
	has_start_value bool
	start_value     f64
	easing          easing.EasingFunction = easing.linear
}

pub struct Glider {
pub mut:
	queue       []Event
	time        f64
	value       f64
	start_value f64
	current     Event
	easing      easing.EasingFunction = easing.linear
	sorting     bool
	dirty       bool
}

pub fn new_glider(value f64) &Glider {
	mut glider := &Glider{
		value: value
		start_value: value
		current: Event{
			time: time.Time{-1.0, 0}
			target_value: value
			has_start_value: false
			start_value: 0.0
			easing: easing.linear
		}
	}

	return glider
}

pub fn (mut glider Glider) add_event(start_time f64, end_time f64, value f64) {
	glider.queue << Event{
		time: time.Time{start_time, end_time}
		target_value: value
		has_start_value: false
		start_value: 0.0
		easing: glider.easing
	}
	glider.dirty = true
}

pub fn (mut glider Glider) add_event_start(start_time f64, end_time f64, start_value f64, end_value f64) {
	glider.queue << Event{
		time: time.Time{start_time, end_time}
		target_value: end_value
		has_start_value: true
		start_value: start_value
		easing: glider.easing
	}
	glider.dirty = true
}

pub fn (mut glider Glider) update(update_time f64) {
	if glider.dirty && glider.sorting {
		// TODO: What the fuck is slice in go
		glider.dirty = false
	}
	glider.time = update_time

	glider.update_current(update_time)

	if glider.queue.len > 0 {
		for i := 0; glider.queue.len > 0 && glider.queue[i].time.start <= update_time; i++ {
			e := &glider.queue[i]

			if e.has_start_value {
				glider.start_value = e.start_value
			} else if glider.current.time.end <= e.time.start {
				glider.start_value = glider.current.target_value
			} else {
				glider.start_value = glider.value
			}

			if glider.current.time.end > e.time.start && e.has_start_value {
				glider.value = e.start_value
			}

			glider.current = e

			if glider.start_value == glider.current.target_value {
				glider.value = glider.current.target_value
			}

			glider.update_current(update_time)
			glider.queue = glider.queue[1..]
			i--
		}
	}
}

pub fn (mut glider Glider) update_current(update_time f64) {
	if update_time < glider.current.time.end {
		e := glider.current
		glider.value = e.easing(update_time - e.time.start, e.start_value, e.target_value - e.start_value,
			e.time.duration())
	} else {
		glider.value = glider.current.target_value
		glider.start_value = glider.value
	}
}
