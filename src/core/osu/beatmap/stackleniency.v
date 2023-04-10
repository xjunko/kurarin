module beatmap

// Ripped off from osr2mp4-core
pub fn (mut beatmap Beatmap) process_stack_position() {
	stack_space := beatmap.difficulty.circle_radius / 10

	preempt := beatmap.difficulty.preempt

	stack_threshold := preempt * beatmap.general.stack_leniency
	stack_distance := 3

	end_index := beatmap.objects.len - 1
	mut extended_end_index := end_index

	start_index := 0
	mut extended_start_index := start_index

	// Do it in reverse
	for i := extended_end_index; i > start_index; i-- {
		mut n := i

		mut object_i := &beatmap.objects[i]

		if object_i.stack_index != 0 || object_i.is_spinner {
			continue
		}

		/*
		If this object is a hitcircle, then we enter this "special" case.
				* It either ends with a stack of hitcircles only, or a stack of hitcircles that are underneath a slider.
				* Any other case is handled by the "is_slider" code below this.
		*/

		if !object_i.is_spinner && !object_i.is_slider {
			n -= 1

			for n >= 0 {
				mut object_n := &beatmap.objects[n]

				// if spinner
				if object_n.is_spinner {
					n -= 1
					continue
				}

				if object_i.get_start_time() - object_n.get_end_time() > stack_threshold {
					break
				}

				end_time := object_n.get_end_time()
				if object_i.get_start_time() - end_time > stack_threshold {
					break
				}

				if n < extended_start_index {
					object_n.stack_index = 0
					extended_start_index = n
				}

				// Object behind a slider
				if object_n.is_slider
					&& object_n.raw_end_position.distance(object_i.raw_position) < stack_distance {
					offset := object_i.stack_index - object_n.stack_index + 1

					for j in n + 1 .. i + 1 {
						mut object_j := &beatmap.objects[j]

						if object_n.raw_end_position.distance(object_j.raw_position) < stack_distance {
							object_j.stack_index -= offset
						}
					}
					break
				}

				// Normal Stacking
				if object_n.raw_position.distance(object_i.raw_position) < stack_distance {
					object_n.stack_index = object_i.stack_index + 1
					object_i = object_n
				}
				n -= 1
			}
		} else if object_i.is_slider {
			n -= 1

			for n >= start_index {
				mut object_n := &beatmap.objects[n]

				if object_n.is_spinner {
					n -= 1
					continue
				}

				if object_i.get_start_time() - object_n.get_start_time() > stack_threshold {
					break
				}

				if object_n.raw_end_position.distance(object_i.raw_position) < stack_distance {
					object_n.stack_index = object_i.stack_index + 1
					object_i = object_n
				}

				n -= 1
			}
		}
	}

	// Apply the stacking
	for mut object in beatmap.objects {
		if object.is_spinner {
			continue
		}
		space := -stack_space * object.stack_index
		object.position.x = object.raw_position.x + space
		object.position.y = object.raw_position.y + space

		object.end_position.x = object.raw_end_position.x + space
		object.end_position.y = object.raw_end_position.y + space
	}
}
