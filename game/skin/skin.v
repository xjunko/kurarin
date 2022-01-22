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

	// skin is not binded somehow
	if !skin.bind {
		logging.fatal("Tried to get texture when not binded.")
	}

	// not in cache
	if name !in skin.cache {
		skin.cache[name] = skin.ctx.create_image(os.join_path(skin.fallback, name + '.png'))
	}

	return skin.cache[name]
}

