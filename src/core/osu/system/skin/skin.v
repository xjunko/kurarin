module skin

import os
import sync
import gg
import framework.logging
import framework.graphic.context

pub const (
	global = &Skin{}
)

const (
	required_files = [
		// Cursor
		'cursor',
		'cursortrail',
		'cursor-top',
		'cursortrailfx',
		// HitCircle
		'hitcircle',
		'hitcircleoverlay',
		'approachcircle',
		// Slider: These files might not exists
		'sliderstartcircleoverlay',
		'sliderstartcircle',
		'hitcircleoverlay',
		'sliderfollowcircle',
		'sliderb',
		// Spinner
		'spinner-circle',
		'spinner-approachcircle',
		// Hit Accuracy
		'hit0',
		'hit50',
		'hit100',
		'hit300',
		// UI shit
		'inputoverlay-background',
		'inputoverlay-key',
	]
)

//
pub fn get_skin() &Skin {
	unsafe {
		mut skin := skin.global
		return skin
	}
}

pub fn bind_context(mut ctx context.Context) {
	mut g := get_skin()
	g.ctx = ctx
	g.bind = true
	g.meta = load_skin_info(g.path)

	logging.info("${@MOD}Skin's context is binded!")

	logging.info('Loading skin assets!')

	for file in skin.required_files {
		logging.debug('Loading: ${file} from skin')
		get_texture(file)
		get_frames(file)
	}
	logging.info('Done!')
}

//

pub struct Skin {
pub mut:
	bind bool
	meta &SkinMetadata    = unsafe { nil }
	ctx  &context.Context = unsafe { nil }
	sync &sync.Mutex      = sync.new_mutex()
	// Internal
	path     string = r'assets/osu/skins/default'
	fallback string = r'assets/osu/skins/default'
	cache    map[string]gg.Image
}

pub fn get_texture(name string) gg.Image {
	mut skin := get_skin()

	if !skin.bind {
		logging.fatal('Graphic context is not binded while getting texture, this is not supposed to happen.')
	}

	return get_texture_with_fallback(name, name)
}

pub fn get_frames(name string) []gg.Image {
	mut skin := get_skin()
	mut frames := []gg.Image{}

	// Check for static version, if found use that one instead.
	if os.exists(os.join_path(skin.fallback, '${name}.png')) {
		frames << get_texture(name)
	}

	// Check for first frame
	mut frame_n := 0

	// The "normal" animations
	for os.exists(os.join_path(skin.fallback, '${name}-${frame_n}.png')) {
		frames << get_texture('${name}-${frame_n}')
		frame_n++
	}

	// Some legacy shit still use this naming
	if frames.len == 0 {
		for os.exists(os.join_path(skin.fallback, '${name}${frame_n}.png')) {
			frames << get_texture('${name}${frame_n}')
			frame_n++
		}
	}

	return frames
}

pub fn get_texture_with_fallback(name string, fallback string) gg.Image {
	mut skin := get_skin()

	// Try get from normal name
	if name !in skin.cache {
		mut original_path := os.join_path(skin.path, name + '.png')

		if !os.exists(original_path) {
			logging.info('[${@METHOD}] File not found in `skin` folder, using the fallback path.')
			original_path = os.join_path(skin.fallback, name + '.png')
		}

		skin.cache[name] = skin.ctx.create_image(original_path)

		// Check if failed
		if skin.cache[name].id == 0 || !os.exists(original_path) {
			logging.debug('Failed getting ${name} from skin, trying ${fallback}!')

			// Use fallback texture name
			original_path = os.join_path(skin.fallback, fallback + '.png')

			if !os.exists(original_path) {
				logging.info('[${@METHOD}] Fallback not found, using the fallback texture name.')
				original_path = os.join_path(skin.fallback, fallback + '.png')
			}

			// Get from fallback
			// println(os.join_path(skin.fallback, fallback + '.png'))
			skin.cache[fallback] = skin.ctx.create_image(os.join_path(skin.fallback, fallback +
				'.png'))
			skin.cache[name] = skin.cache[fallback]

			// If still fail, then fuck it, we ballin.
			if skin.cache[fallback].id == skin.ctx.texture_not_found.id {
				skin.cache.delete(fallback)
				skin.cache.delete(name)
			}
		}
	}

	return skin.cache[name]
}
