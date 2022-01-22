module x

/* "x" module is for shit that im not sure where to put so itll be here for now */

import framework.logging
import framework.math.vector

pub const (
	resolution = &Resolution{}
)

pub struct Resolution {
	pub mut:
		resolution 		vector.Vector2 = vector.Vector2{1280, 720}
		playfield  		vector.Vector2
		playfield_scale f64
		offset          vector.Vector2
		scale			f64
}

pub fn (mut res Resolution) calculate() {
	// The "old" one
	// res.playfield_scale = 595.5 / 768
	// res.playfield.y = res.resolution.y * res.playfield_scale
	// res.playfield.x = res.playfield.y * 4/3
	// res.scale = res.resolution.y / 768
	// res.playfield_scale *= res.scale * 2
	// res.offset.x = (res.resolution.x - res.playfield.x) / 2.1
	// res.offset.y = (res.resolution.y - res.playfield.y) / 1.9
	
	res.playfield.y = res.resolution.y * 0.8
	res.playfield.x = res.playfield.y * 4/3
	res.playfield_scale = res.playfield.x / 512
	res.scale = res.resolution.y / 768
	res.offset.x = (res.resolution.x - res.playfield.x) / 2.0
	res.offset.y = (res.resolution.y * 0.1)

	logging.info(res.str())
	logging.debug("Resolution calculated!")
}



//
fn init() {
	mut r := resolution
	r.calculate()
}