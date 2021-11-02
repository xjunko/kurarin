module beatmap

import object

// epic trolling
[inline]
pub fn end_distance(a &object.IHitObject, b &object.IHitObject) f64 {
	return a.end_position.distance(b.position)
}

[inline]
pub fn distance(a &object.IHitObject, b &object.IHitObject) f64 {
	return a.position.distance(b.position)
}

pub fn (mut beatmap Beatmap) process_stack_position() {
	// copied from osr2mp4 cuz danser's sus
	cs := beatmap.difficulty_math.cs
	scale := (1.0 - 0.7 * (cs - 5) / 5) / 2
	stack_space := scale * 6.4

	preempt := beatmap.difficulty_math.preempt

	stack_threshold := preempt * beatmap.general.stackleniency
	stack_distance := 3

	end_index := beatmap.objects.len - 1
	mut extended_end_index := end_index

	start_index := 0
	mut extended_start_index := start_index

	// reverse
	for i := extended_end_index; i > start_index; i-- {
		mut n := i

		mut object_i := &beatmap.objects[i]
		if object_i.stacking != 0 || object_i.is_spinner {
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
				

				if object_n.is_spinner {
					n -= 1
					continue
				}

				if object_i.time.start - object_n.time.end > stack_threshold {
					break
				}

				end_time := object_n.time.end
				if object_i.time.start - end_time > stack_threshold {
					break
				}

				if n < extended_start_index {
					object_n.stacking = 0
					extended_start_index = n
				}

				// Object behind a slider
				if object_n.is_slider && end_distance(object_n, object_i) < stack_distance {
					offset := object_i.stacking - object_n.stacking + 1

					for j in n + 1 .. i + 1 {
						mut object_j := &beatmap.objects[j]

						if end_distance(object_n, object_j) < stack_distance {
							object_j.stacking -= offset
						}
					}
					break
				}

				// Normal Stacking
				if distance(object_n, object_i) < stack_distance {
					object_n.stacking = object_i.stacking + 1
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

				if object_i.time.start - object_n.time.start > stack_threshold {
					break
				}

				if end_distance(object_n, object_i) < stack_distance {
					object_n.stacking = object_i.stacking + 1
					object_i = object_n
				}

				n -= 1
			}
		}

	}

	// Apply the stacking
	for mut object in beatmap.objects {
		if object.is_spinner { continue }
		space := -stack_space * object.stacking
		object.position.x += space
		object.position.y += space
		object.end_position.x += space
		object.end_position.y += space
	}

}