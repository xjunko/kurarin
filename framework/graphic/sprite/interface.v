module sprite

import library.gg
import gx

import framework.math.time
import framework.math.vector
import framework.math.transform

[params]
pub struct CommonSpriteArgument {
	pub mut:
		ctx   &gg.Context = voidptr(0)
		time  f64
		delta f64
}

[params]
pub struct CommonSpriteSizeResetArgument {
	pub:
		factor f64 = 1.0
		size   vector.Vector2
}

pub interface ISprite {
	mut:
		time     time.Time
		origin   vector.Vector2
		position vector.Vector2
		size     vector.Vector2
		color    gx.Color
		additive bool

		update(f64)
		draw(CommonSpriteArgument)
		draw_and_update(CommonSpriteArgument)

		add_transform(transform.Transform)

		reset_size_based_on_texture(CommonSpriteSizeResetArgument)
		reset_attributes_based_on_transforms()

		is_drawable_at(f64) bool

		get_texture() &gg.Image
}