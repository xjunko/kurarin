module sprite

import lib.gg
import game.logic
import framework.math.vector
import framework.math.time


pub struct DrawConfig {
	pub mut:
		ctx    &gg.Context
		time   f64
		offset vector.Vector2
		size   vector.Vector2
		scale  f64 = 1
		logic  logic.HitCircle
		draw_logic bool
}

// TODO: idfk
pub fn (cfg DrawConfig) get_localize_position(size vector.Vector2, position vector.Vector2, origin vector.Vector2) vector.Vector2 {
	origin_cved := size.scale_(cfg.scale).scale_origin_(origin)
	return position.scale_(cfg.scale).sub_(origin_cved).add_(cfg.offset.scale_(cfg.scale))
	
}

pub interface IDrawable {
	mut:
		time &time.Time

	update(f64)
	draw(DrawConfig)
	draw_and_update(DrawConfig)
}