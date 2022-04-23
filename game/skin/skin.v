module skin

import os
import sync
import library.gg

import framework.logging

const (
	global = &Skin{}
)

//
pub fn get_skin() &Skin {
	mut skin := global
	return skin
}

pub fn bind_context(mut ctx &gg.Context) {
	mut g := get_skin()
	g.ctx = ctx
	g.bind = true

	logging.info("Skin's context is binded!")
}
//

pub struct Skin {
	pub mut:
		bind   bool 
		ctx    &gg.Context = voidptr(0)
		sync   &sync.Mutex = sync.new_mutex()

		// Skin shit
		path  	 string
		fallback string = r"assets/skins/default" // Temporary
		cache 	 map[string]gg.Image
}

pub fn get_texture(name string) gg.Image {
	mut skin := get_skin()

	if !skin.bind {
		logging.fatal("Graphic context is not binded while getting texture, this is not supposed to happen.")
	}

	return get_texture_with_fallback(name, name)
}

pub fn get_frames(name string) []gg.Image {
	mut skin := get_skin()

	// Check for first frame
	mut frames := []gg.Image{}
	mut frame_n := 0

	for os.exists(os.join_path(skin.fallback, '${name}-${frame_n}.png')) {
		frames << get_texture('${name}-${frame_n}')
		frame_n++
	}

	return frames
}


pub fn get_texture_with_fallback(name string, fallback string) gg.Image {
	mut skin := get_skin()

	// Try get from normal name
	if name !in skin.cache {
		skin.cache[name] = skin.ctx.create_image(os.join_path(skin.fallback, name + '.png'))

		// Check if failed
		if skin.cache[name].id == 0 {
			logging.error("Failed getting ${name} from skin, trying ${fallback}!")
			
			// Get from fallback
			skin.cache[fallback] = skin.ctx.create_image(os.join_path(skin.fallback, fallback + '.png'))
			skin.cache[name] = skin.cache[fallback]
		}
	}

	return skin.cache[name]
}