module beatmap

import os
import difficulty
import timing
import object
import library.gg
import gx
import sync

import sokol.gfx
import sokol.sgl

import framework.ffmpeg
import framework.logging
import framework.math.time
import framework.math.vector
import framework.graphic.sprite

import game.x
import game.skin
import game.audio
import game.settings


import storyboard
import object.graphic

pub struct BeatmapGeneralInfo {
	pub mut:
		bg_filename    string [_SKIP]
		video_filename string [_SKIP]
		video_offset   f64    [_SKIP]
		audio_filename string [AudioFilename]
		stack_leniency f64    [StackLeniency]
		widescreen 	   bool   [WidescreenStoryboard]
}

pub struct BeatmapMetadataInfo {
	pub mut:
		title   string [Title]
		artist  string [Artist]
		version string [Version]
}

pub struct BeatmapDifficultyInfo {
	difficulty.Difficulty
}

pub struct Beatmap {
	pub mut:
		root        string
		filename    string
		general     BeatmapGeneralInfo
		metadata    BeatmapMetadataInfo
		difficulty  BeatmapDifficultyInfo
		timing      timing.Timings

		ctx         &gg.Context = voidptr(0)
		storyboard  &storyboard.Storyboard = &storyboard.Storyboard{}
		background  []sprite.ISprite
		objects     []object.IHitObject
		queue       []object.IHitObject
		finished    []object.IHitObject
		combo_color []gx.Color
		objects_i   int

		// Temporary
		playfield_size   vector.Vector2
		temp_beatmap_sb  []string
		last_update  	 f64
		update_lock  	 &sync.Mutex = sync.new_mutex() // To prevent race, note that this might block the entire thing if draw or update method got stuck
}

// Method
pub fn (mut beatmap Beatmap) bind_context(mut ctx &gg.Context) {
	beatmap.ctx = ctx
}

pub fn (mut beatmap Beatmap) ensure_background_loaded() {
	// TODO: use storyboard
	if beatmap.storyboard.sprites.len == 0 {
		mut has_video := false
		if os.exists(beatmap.get_video_path()) && !settings.global.gameplay.disable_background_video {
			has_video = true
			mut video := ffmpeg.make_video_sprite(beatmap.get_video_path(), mut beatmap.ctx, beatmap.general.video_offset)
			beatmap.storyboard.video = video
		}


		// Nothing on the storyboard, make our own background
		image := beatmap.ctx.create_image(beatmap.get_bg_path())
		mut ratio := (1280.0 / f64(image.width)) / storyboard.storyboard_scale

		// Make sure the height is >= 720
		for ((f64(image.height) * ratio) * storyboard.storyboard_scale ) < 720 {
			ratio += 0.05
		}

		end_size := vector.Vector2{f64(image.width * ratio), f64(image.height * ratio)}

		mut beatmap_bg := &sprite.Sprite{
			origin: vector.centre,
			textures: [image],
			always_visible: true,
			position: vector.Vector2{320.0, 240.0}
		}

		// fade
		beatmap_bg.add_transform(typ: .fade, time: time.Time{-1500, -500}, before: [0.0], after: [255.0])	

		if has_video {
			beatmap_bg.add_transform(typ: .fade, time: time.Time{1100, 1200}, before: [0.0])	
			beatmap_bg.always_visible = false
		}

		// done
		beatmap_bg.reset_size_based_on_texture(size: end_size)
		beatmap_bg.reset_attributes_based_on_transforms()

		beatmap.storyboard.sprites << beatmap_bg
		logging.info("No background, making one!")
	}
}

pub fn (mut beatmap Beatmap) ensure_hitsound_loaded() {
	logging.debug("Loading hitsounds!")
	audio.init_samples(skin.get_skin().fallback, beatmap.root)
	logging.debug("Loaded hitsound")
}

pub fn (mut beatmap Beatmap) reset() {
	// Normal shit
	beatmap.process_stack_position()

	mut combo_number := 1
	for i, mut o in beatmap.objects {
		if o.is_new_combo() {
			combo_number = 1
		}

		// Set colors
		color := beatmap.combo_color[o.color_offset % beatmap.combo_color.len]
		o.color = [f64(color.r), f64(color.g), f64(color.g)]

		o.set_id(i)
		o.set_combo_number(combo_number)
		o.set_timing(beatmap.timing)
		o.set_difficulty(beatmap.difficulty.Difficulty)

		combo_number++
	}

	// Storyboard
	beatmap.storyboard = storyboard.parse_storyboard([beatmap.get_sb_path(), ""][int(settings.global.gameplay.disable_storyboard)], mut beatmap.ctx)
	if !settings.global.gameplay.disable_storyboard {
		beatmap.storyboard.parse_lines(beatmap.temp_beatmap_sb) // Parse beatmap's storyboard too (if theres any)
	}
	logging.info("Storyboard loaded!")

	beatmap.ensure_background_loaded()
	beatmap.ensure_hitsound_loaded()
}

pub fn (mut beatmap Beatmap) update(time f64, boost f32) {
	beatmap.update_lock.@lock()

	for i := beatmap.objects_i; i < beatmap.objects.len; i++ {
		if (time >= (beatmap.objects[i].get_start_time() - beatmap.difficulty.preempt)) &&
		   (time <= (beatmap.objects[i].get_end_time() + difficulty.hit_fade_out + beatmap.difficulty.hit50)) {
			   logging.debug("Added hitobject ${i} into queue")
			   beatmap.queue << &beatmap.objects[i]
			   beatmap.objects_i++
			   continue
		   }
	}

	// Queue
	for i := 0; i < beatmap.queue.len; i++ {
		// Remove if ended
		if time >= (beatmap.queue[i].get_end_time() + difficulty.hit_fade_out + beatmap.difficulty.hit50) {
			logging.debug("Removed hitobject ${i} from queue.")
			beatmap.finished << &beatmap.queue[i]
			beatmap.queue = beatmap.queue[1..]
			i--
			continue
		}

		beatmap.queue[i].update(time)
		beatmap.queue[i].set_boost_level(boost)
	}

	// Slider renderer scale
	graphic.update_boost_level(boost)

	// Storyboard
	beatmap.storyboard.update(time)

	// Playfield size update
	// TODO: make this customizeable or smth
	// Since this is math based animation instead of transformation (if that makes sense), we need to set the actual size after the lead_in_time ends
	if beatmap.last_update + settings.global.gameplay.lead_in_time >= settings.global.gameplay.lead_in_time - 2000 && beatmap.last_update + settings.global.gameplay.lead_in_time < settings.global.gameplay.lead_in_time {
		beatmap.playfield_size.x = x.resolution.playfield.x * 0.25 + beatmap.playfield_size.x - beatmap.playfield_size.x * 0.25
		beatmap.playfield_size.y = x.resolution.playfield.y * 0.25 + beatmap.playfield_size.y - beatmap.playfield_size.y * 0.25
	} else if beatmap.last_update + settings.global.gameplay.lead_in_time > settings.global.gameplay.lead_in_time {
		// Over the lead_in_time, put actual size
		beatmap.playfield_size.x = x.resolution.playfield.x
		beatmap.playfield_size.y = x.resolution.playfield.y
	}

	// Done
	beatmap.last_update = time
	beatmap.update_lock.unlock()
}

pub fn (mut beatmap Beatmap) post_update(time f64) {
	// Note that this only used for freeing slider (cuz we're using shaders, vertex and stuff and those eat lots of ram)
	// and also for some reason sokol doesnt support freeing it (maybe it does) on another thread, its only working
	// when we freeing it on draw calls /shrug pretty weird ngl
	// EDIT: ignore what i said earlier
	for i := 0; i < beatmap.finished.len; i++ {
		beatmap.finished[i].post_update(time)
		beatmap.finished = beatmap.finished[1..]
		i--
	}
}

pub fn (mut beatmap Beatmap) draw() {
	beatmap.update_lock.@lock()

	// Background/Storyboard draws
	gfx.begin_default_pass(graphic.global_renderer.pass_action, 1280, 720)

	beatmap.storyboard.draw() // Includes background

	// Shitty background dim
	beatmap.ctx.draw_rect_filled(0, 0, 1280, 720, gx.Color{0,0,0, byte(settings.global.gameplay.background_dim)})

	// Playfield
	// Insides
	beatmap.ctx.draw_rect_filled(f32((1280 - beatmap.playfield_size.x) / 2), f32((720 - beatmap.playfield_size.y) / 2), f32(beatmap.playfield_size.x), f32(beatmap.playfield_size.y), gx.Color{0,0,0, 150})

	// Outline
	beatmap.ctx.draw_rect_empty(f32((1280 - beatmap.playfield_size.x) / 2), f32((720 - beatmap.playfield_size.y) / 2), f32(beatmap.playfield_size.x), f32(beatmap.playfield_size.y), gx.white)

	// Done
	sgl.draw()
	gfx.end_pass()
	gfx.commit()

	
	// Draw stuff on its own "layer" or whatever it was called in 
	// sokol.
	if !settings.global.gameplay.disable_hitobject { // We might want hitcircle hitsounds but not the hitcircle itself, so on draw calls ignored it but not on update calls
		for i := beatmap.queue.len - 1; i >= 0; i-- {
			mut hitobject := &beatmap.queue[i]
			// Render slider
			if mut hitobject is object.Slider {
				if beatmap.last_update <= hitobject.get_start_time() && hitobject.hitcircle.hitcircle.is_drawable_at(beatmap.last_update) {
					hitobject.slider_renderer_attr.update_vertex_progress(0, 0)
					hitobject.slider_renderer_attr.draw_slider(hitobject.hitcircle.hitcircle.color.a, hitobject.color)
				}

				if beatmap.last_update >= hitobject.get_start_time() && hitobject.slider_overlay_sprite.is_drawable_at(beatmap.last_update) {
					hitobject.slider_renderer_attr.update_vertex_progress(0, 0)
					hitobject.slider_renderer_attr.draw_slider(hitobject.slider_overlay_sprite.color.a, hitobject.color)
				}
			}

			// Render hitcircle
			gfx.begin_default_pass(graphic.global_renderer.pass_action, 1280, 720)
			beatmap.queue[i].draw(ctx: beatmap.ctx, time: beatmap.last_update)
			sgl.draw()
			gfx.end_pass()
			gfx.commit()
		}
	}

	// POST update, only used for freeing slider
	// Note that in linux: this doesnt matter, it can be placed in draw or update loop
	// But on windows: This NEED to be in here or everything shits itself and crash.
	beatmap.post_update(beatmap.last_update)
	
	//
	beatmap.update_lock.unlock()
}

// Property
pub fn (beatmap &Beatmap) get_audio_path() string {
	return os.join_path(beatmap.root, beatmap.general.audio_filename)
}

pub fn (beatmap &Beatmap) get_bg_path() string {
	return os.join_path(beatmap.root, beatmap.general.bg_filename)
}

pub fn (beatmap &Beatmap) get_video_path() string {
	return os.join_path(beatmap.root, beatmap.general.video_filename)
}

pub fn (beatmap &Beatmap) get_sb_path() string {
	// TODO: per-difficulty sb
	if files := os.glob(os.join_path(beatmap.root, "*.osb")) {
		return files[0] or { "" }
	}

	return ""
}