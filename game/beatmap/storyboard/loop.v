module storyboard

import math
import framework.math.transform

pub struct LoopProcessor {
	pub mut:
		start f64
		repeats i64
		transforms []&transform.Transform
}

pub fn (mut loop LoopProcessor) add(mut command []string) {
	loop.transforms << parse_command(mut command)
}

pub fn (mut loop LoopProcessor) finalize() []&transform.Transform {
	mut transforms := []&transform.Transform{}

	mut indexed := false
	mut start_time := 0.0
	mut end_time := 0.0

	for t in loop.transforms {
		if !indexed {
			start_time = t.time.start
			end_time = t.time.end
			indexed = true
			continue
		}

		start_time = math.min<f64>(start_time, t.time.start)
		end_time = math.max<f64>(end_time, t.time.end)
	}

	iteration_time := end_time - start_time

	for i := i64(0); i < loop.repeats; i++ {
		part_start := loop.start + f64(i) * iteration_time

		for t in loop.transforms {
			transforms << t.clone(
				start: t.time.start + part_start,
				end:  t.time.end + part_start
			)
		}
	}

	return transforms
}

pub fn make_loop_processor(data []string) &LoopProcessor {
	mut loop := &LoopProcessor{}
	
	loop.start = data[1].f64()
	loop.repeats = data[2].i64()

	if loop.repeats < 1 {
		loop.repeats = 1
	}

	return loop
}