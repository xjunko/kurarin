module gg

import os
import sync

pub const (
	current_ctx = &Context{ft: 0}
	current_skin = &Skin{}
	default_skin = 'default4'
)

pub fn make_skin_struct(mut ctx &Context) &Skin {
	println('> Skin cache initialized!')
	mut skin := &Skin{ctx: ctx}
	return skin
}

pub fn get_texture_from_skin(name string) Image {
	mut ctx := current_ctx
	return ctx.get_texture_from_skin(name)
}

pub fn (mut ctx Context) get_texture_from_skin(name string) Image {
	mut skin := current_skin
	return skin.get_texture_from_skin(name)
}

// Skin shit
pub struct Skin {
	pub mut:
		ctx               &Context = voidptr(0)
		texture_lock      &sync.Mutex = sync.new_mutex()

		skin_cache        map[string]Image
		current_skin      string = default_skin
}

pub fn (mut s Skin) get_texture_from_skin(name string) Image {
	s.texture_lock.@lock()
	defer { s.texture_lock.unlock() }

	if name !in s.skin_cache {
		s.skin_cache[name] = s.ctx.create_image(os.join_path('assets/skins/default/${name}.png'))
	}

	return s.skin_cache[name]
}