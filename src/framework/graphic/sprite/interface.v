module sprite

import gg
import gx
import framework.math.time
import framework.math.camera
import framework.math.vector
import framework.math.transform
import framework.graphic.context

@[params]
pub struct CommonSpriteArgument {
pub mut:
	ctx   &context.Context = unsafe { nil }
	time  f64
	delta f64
	scale f64 = f64(1.0)
	batch bool
	// Extra scale so we can use it with boost
	camera camera.Camera
}

@[params]
pub struct CommonSpriteSizeResetArgument {
pub:
	factor   f64 = 1.0
	size     vector.Vector2[f64]
	source   vector.Vector2[f64]
	fit_size bool
	// If false, just overide, if true factor it based on source
}

pub interface ISprite {
mut:
	id             int
	time           time.Time
	origin         vector.Origin
	position       vector.Vector2[f64]
	size           vector.Vector2[f64]
	color          gx.Color
	angle          f64
	additive       bool
	always_visible bool
	update(f64)
	draw(CommonSpriteArgument)
	add_transform(transform.Transform)
	reset_transform()
	remove_transform_by_type(transform.TransformType)
	reset_size_based_on_texture(CommonSpriteSizeResetArgument)
	reset_attributes_based_on_transforms()
	is_drawable_at(f64) bool
	get_texture() &gg.Image
}
