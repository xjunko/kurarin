module object

const circle = 1 << 0
const slider = 1 << 1
const new_combo = 1 << 2
const spinner = 1 << 3

pub fn make_object(items []string) IHitObject {
	object_type := items[3].i8()

	if (object_type & object.circle) > 0 {
		return make_circle(items)
	} else if (object_type & object.slider) > 0 {
		return make_slider(items)
	} else if (object_type & object.spinner) > 0 {
		return make_spinner(items)
	}

	panic('THE FUCK')
}
