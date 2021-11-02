module resolution

pub const (
	osu_width = 512
	osu_height = 384
	global = &Resolution{width: 1280, height: 720}
)

pub struct Resolution {
	pub mut:
		width f32
		height f32
			
		//
		playfield_scale f32
		playfield_width f32
		playfield_height f32
		scale f32
		right_offset f32
		down_offset f32

		// sb
		storyboard_scale f32
		storyboard_width f32
		storyboard_height f32
}

pub fn (mut r Resolution) calculate() {
	//
	r.playfield_scale = 595.5/768
	r.playfield_height = r.height * r.playfield_scale
	r.playfield_width = r.playfield_height * 4/3
	r.scale = r.height / 768
	r.playfield_scale *= r.scale * 2

	// sb
	r.storyboard_scale = r.height / 480
	r.storyboard_width = 854 * r.storyboard_scale
	r.storyboard_height = 480 * r.storyboard_scale

	//
	r.right_offset = (r.width - r.playfield_width) / 2.1
	r.down_offset = (r.height - r.playfield_height) / 1.9

	//
	// println('> Resolution: ${r}')
}

pub fn init() {
	mut r := global
	r.calculate()
}