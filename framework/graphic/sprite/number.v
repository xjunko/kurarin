module sprite

import lib.gg
import framework.math.vector

// haha
pub struct ComboSprite {
	Sprite

	pub mut:
		number  	int
		number_len  int
		number_str  string
		number_img  []&gg.Image
}

pub fn (mut combo ComboSprite) pre_init() {
	// similar to normal sprite but abit different
	img := &combo.textures[0] // Limit to 10 for now
	combo.change_size(size: vector.Vector2{img.width, img.height}) // n size

	// tbh idk if this actually needed but i like to keep the draw calls as
	// cheap as possible so might as well cache literally everything
	combo.number_str = combo.number.str()
	combo.number_len = combo.number_str.len
	// this is expensive (or slow) so had to cache beforehand
	for digit in 0 .. combo.number_len {
		combo.number_img << &combo.textures[combo.number_str[digit].str_escaped().int()]
	}
}

pub fn (mut combo ComboSprite) update(time f64) {
	combo.Sprite.update(time)
}

pub fn (mut combo ComboSprite) draw(cfg DrawConfig) {
	// whoops almost forgot to add this
	if !combo.check_if_drawable(cfg.time) && !combo.always_visible { return }

	// ayayaya
	n_size := combo.size.scale(cfg.scale)
	cv_size := vector.Vector2{
		n_size.x * combo.number_len,
		n_size.y
	}
	origin := cv_size.multiply(combo.origin)

	// position
	position := combo.position.scale(cfg.scale).sub(origin).add(cfg.offset.scale(cfg.scale))

	// draw
	for n, img in combo.number_img {
		cfg.ctx.draw_image_with_config(
			img: img,
			img_id: img.id,
			img_rect: gg.Rect{
				x: f32(position.x + (n_size.x * n)),
				y: f32(position.y),
				width: f32(n_size.x),
				height: f32(n_size.y)
			}
			color: combo.color,
		)
	}
}

pub fn (mut combo ComboSprite) draw_and_update(cfg DrawConfig) {
	combo.Sprite.draw_and_update(cfg)
}