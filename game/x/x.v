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

	// osr2mp4
	res.playfield.y = res.resolution.y * 0.8
	res.playfield.x = res.playfield.y * 4/3
	res.playfield_scale = res.playfield.x / 512
	res.scale = res.resolution.y / 768
	res.offset.x = (res.resolution.x - res.playfield.x) / 2.0
	res.offset.y = (res.resolution.y * 0.1)

	// mcosu
	// res.playfield = get_playfield_size(res)
	// res.playfield_scale = get_playfield_size_factor(res)
	// res.offset = get_playfield_offset(res)
	// res.scale = res.resolution.y / 768

	logging.info(res.str())
	logging.debug("Resolution calculated!")
}


// from mcosu
pub fn get_playfield_size_factor(res Resolution) f64 {
	screen_width := res.resolution.x
	top_border_size := 0.117 * res.resolution.y
	bottom_border_size := 0.0834 * res.resolution.y
	screen_height := res.resolution.y - bottom_border_size - top_border_size

	if res.resolution.x / 512.0 > screen_height / 384.0 {
		return screen_height / 384.0
	} else {
		return screen_width / 512.0
	}
}

pub fn get_playfield_size(res Resolution) vector.Vector2 {
	return vector.Vector2{512.0, 384.0}.scale(get_playfield_size_factor(res))
}

pub fn get_playfield_offset(res Resolution) vector.Vector2 {
	playfield_size := get_playfield_size(res)
	bottom_border_size := 0.0834 * res.resolution.y
	playfield_y_offset := (res.resolution.y / 2.0 - (playfield_size.y / 2.0)) - bottom_border_size

	return vector.Vector2{(res.resolution.x - playfield_size.x) / 2.0, (res.resolution.y - playfield_size.y) / 2.0 + playfield_y_offset}
	
}



//
fn init() {
	mut r := resolution
	r.calculate()
}