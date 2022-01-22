module transform


import framework.math.easing
import framework.math.time
import framework.math.vector

pub enum TransformType {
	move
	move_x
	move_y
	angle
	color
	fade
	scale
	scale_factor
}

pub struct Transform {
	pub mut:
		typ    TransformType [required]
		easing easing.EasingFunction = easing.linear
		time   time.Time [required]
		before []f64 [required]
		after  []f64
}

pub fn (mut t Transform) ensure_both_slots_is_filled_in() {
	if t.after.len != t.before.len {
		t.after = t.before.clone()
	}
}

pub fn (t Transform) as_one(time f64) f64 {
	return t.easing(
			time - t.time.start, t.before[0], t.after[0] - t.before[0], t.time.duration()
		)
}

pub fn (t Transform) as_two(time f64) []f64 {
	return [
		t.easing(
			time - t.time.start, t.before[0], t.after[0] - t.before[0], t.time.duration()
		),
		t.easing(
			time - t.time.start, t.before[1], t.after[1] - t.before[1], t.time.duration()
		)
	]
}

pub fn (t Transform) as_vector(time f64) vector.Vector2 {
	v := t.as_two(time) // pretty sure theres a way to do this in one line
	return vector.Vector2{
		x: v[0],
		y: v[1]
	}
}

pub fn (t Transform) as_three(time f64) []f64 {
	return [
		t.easing(time - t.time.start, t.before[0], t.after[0] - t.before[0], t.time.duration()),
		t.easing(time - t.time.start, t.before[1], t.after[1] - t.before[1], t.time.duration()),
		t.easing(time - t.time.start, t.before[2], t.after[2] - t.before[2], t.time.duration()),	
	]
}