module sprite

import lib.gg
import framework.math.vector
import framework.math.time


pub struct DrawConfig {
	pub mut:
		ctx    &gg.Context
		time   f64
		offset vector.Vector2
		size   vector.Vector2
		scale  f64 = 1
		extra  vector.Vector2
}

// TODO: idfk
pub fn (cfg DrawConfig) get_localize_position(size vector.Vector2, position vector.Vector2, origin vector.Vector2) vector.Vector2 {
	origin_cved := size.scale(cfg.scale).multiply(origin)
	return position.scale(cfg.scale).sub(origin_cved).add(cfg.offset.scale(cfg.scale))
	
}

pub interface IDrawable {
	mut:
		time &time.Time
		skip_offset bool
		special     bool // For slider with its own shader/pipeline shit

	update(f64)
	draw(DrawConfig)
	draw_and_update(DrawConfig)
}