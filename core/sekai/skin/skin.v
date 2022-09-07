module skin

import os
import library.gg

import framework.logging

const (
	global = &Skin{}
)

pub struct Skin {
	pub mut:
		bind bool
		ctx &gg.Context = voidptr(0)

		fallback string = "assets/psekai/textures"
		cache map[string]gg.Image
}

// Bind
pub fn bind_context(mut ctx &gg.Context) {
	mut g := get_skin()
	g.ctx = ctx
	g.bind = true

	logging.info("[${@MOD}] Skin's context is binded!")
}

// FNs
pub fn get_skin() &Skin {
	unsafe {
		mut skin := global
		return skin
	}
}

pub fn get_texture(name string) gg.Image {
	mut skin := get_skin()

	if !skin.bind {
		logging.fatal("Graphic context is not binded while getting texture, this is not supposed to happen.")
	}

	return get_texture_with_fallback(name, name)
}

pub fn get_texture_with_fallback(name string, fallback string) gg.Image {
	mut skin := get_skin()

	// Try get from normal name
	if name !in skin.cache {
		skin.cache[name] = skin.ctx.create_image(os.join_path(skin.fallback, name + '.png'))

		// Check if failed
		if skin.cache[name].id == 0 {
			logging.debug("Failed getting ${name} from skin, trying ${fallback}!")
			
			// Get from fallback
			// println(os.join_path(skin.fallback, fallback + '.png'))
			skin.cache[fallback] = skin.ctx.create_image(os.join_path(skin.fallback, fallback + '.png'))
			skin.cache[name] = skin.cache[fallback]
		}
	}

	return skin.cache[name]
}