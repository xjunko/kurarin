module scenes

import osu

import library.gg

pub struct Scene {
	mut:
		last_time f64
	
	pub mut:
		g_osu &osu.Osu
		ctx   &gg.Context = voidptr(0)
}

pub fn (mut scene Scene) init(mut ctx &gg.Context) {
	scene.ctx = ctx
}

pub fn (mut scene Scene) update(time f64) {
	scene.last_time = time
}

pub fn (mut scene Scene) draw() {

}