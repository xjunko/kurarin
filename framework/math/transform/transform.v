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
	additive
	flip_vertically
	flip_horizontally
	vector_shape
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

pub fn (t Transform) as_one(update_time f64) f64 {
	return t.easing(
			update_time - t.time.start, t.before[0], t.after[0] - t.before[0], t.time.duration()
		)
}

pub fn (t Transform) as_two(update_time f64) []f64 {
	return [
		t.easing(
			update_time - t.time.start, t.before[0], t.after[0] - t.before[0], t.time.duration()
		),
		t.easing(
			update_time - t.time.start, t.before[1], t.after[1] - t.before[1], t.time.duration()
		)
	]
}

pub fn (t Transform) as_vector(update_time f64) vector.Vector2 {
	v := t.as_two(update_time) // pretty sure theres a way to do this in one line
	return vector.Vector2{
		x: v[0],
		y: v[1]
	}
}

pub fn (t Transform) as_three(update_time f64) []f64 {
	return [
		t.easing(update_time - t.time.start, t.before[0], t.after[0] - t.before[0], t.time.duration()),
		t.easing(update_time - t.time.start, t.before[1], t.after[1] - t.before[1], t.time.duration()),
		t.easing(update_time - t.time.start, t.before[2], t.after[2] - t.before[2], t.time.duration()),	
	]
}

pub fn (t Transform) as_four(update_time f64) []f64 {
	return [
		t.easing(update_time - t.time.start, t.before[0], t.after[0] - t.before[0], t.time.duration()),
		t.easing(update_time - t.time.start, t.before[1], t.after[1] - t.before[1], t.time.duration()),
		t.easing(update_time - t.time.start, t.before[2], t.after[2] - t.before[2], t.time.duration()),	
		t.easing(update_time - t.time.start, t.before[3], t.after[3] - t.before[3], t.time.duration()),	
	]
}


pub fn (t Transform) clone(current_time time.Time) &Transform {
	return &Transform{
		typ: t.typ,
		easing: t.easing,
		time: current_time,
		before: t.before,
		after: t.after,
	}
}