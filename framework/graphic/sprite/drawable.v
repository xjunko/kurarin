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

pub interface IDrawable {
	mut:
		time &time.Time

	update(f64)
	draw(DrawConfig)
	draw_and_update(DrawConfig)
}