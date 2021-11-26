module object

import framework.math.vector
import framework.math.time

import game.math.difficulty
import game.math.timing

pub struct MakeArguments {
	mut:
		id     int
		items  []string
		color  []f64
		diff   difficulty.Difficulty
		timing timing.TimingPoint
		
		is_spinner bool
		is_slider  bool
}

pub fn make_hitobject(arg MakeArguments) IHitObject {
	object_type := arg.items[3].int()

	if (object_type & 1) > 0 {
		return make_circle(arg)
	} else if (object_type & 2) > 0 {
		return make_slider(arg)
	} else if (object_type & 8) > 0 {
		return make_spinner(arg)
	}

	return make_circle(arg)
}

// make FNs
pub fn make_circle(arg MakeArguments) &HitObject {
	mut position := vector.Vector2{arg.items[0].f64(), arg.items[1].f64()}
	mut time := time.Time{arg.items[2].f64(), arg.items[2].f64()}

	mut hitobject := &HitObject{
		id: arg.id,
		position: position,
		end_position: position,
		time: time,
		is_spinner: arg.is_spinner,
		is_slider: arg.is_slider,
		diff: arg.diff,
		timing: arg.timing,
		data: arg.items,
		color: arg.color,
	}
	hitobject.pre_init()

	return hitobject
}

pub fn make_spinner(arg MakeArguments) &Spinner {
	mut position := vector.Vector2{arg.items[0].f64(), arg.items[1].f64()}
	mut time := time.Time{arg.items[2].f64(), arg.items[2].f64()}

	mut hitobject_arg := arg
	hitobject_arg.is_spinner = true
	mut hitobject := make_circle(hitobject_arg)
	mut spinner := &Spinner{
		HitObject: hitobject
		id: arg.id,
		position: position,
		end_position: position,
		time: time
	}

	return spinner
}

pub fn make_slider(arg MakeArguments) &Slider {
	mut position := vector.Vector2{arg.items[0].f64(), arg.items[1].f64()}
	mut time := time.Time{arg.items[2].f64(), arg.items[2].f64()}

	mut hitobject_arg := arg
	hitobject_arg.is_slider = true
	mut hitobject := make_circle(hitobject_arg)
	mut slider := &Slider{
		HitObject: hitobject,
		id: arg.id,
		position: position,
		end_position: position,
		time: time
	}

	return slider

}