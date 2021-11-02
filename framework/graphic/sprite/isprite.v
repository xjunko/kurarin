module sprite

import gx

import framework.transform
import framework.math.time
import framework.math.vector

pub interface ISprite {
	mut:
	time      &time.Time
	position  &vector.Vector2
	size      vector.Vector2
	base_size vector.Vector2
	color     gx.Color
	angle     f64
	z         int

	always_visible bool
	transforms     []transform.Transform

	// utils FNs
	add_transform(AddTransformArgument)
	after_add_transform_reset()
	change_size(vector.Vector2)
	remove_all_transform_with_type(transform.TransformType)
	check_if_drawable(f64) bool


	// draw FNs
	draw(DrawConfig)
	draw_and_update(DrawConfig)
}