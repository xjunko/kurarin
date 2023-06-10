module gameplay

import gg
import sokol.gfx
import sokol.sgl
import sokol.sapp
import mohamedlt.sokolgp as sgp
import framework.audio
import framework.graphic.context
import core.common.settings
import core.osu.x
import core.osu.system.skin
import core.osu.system.player
import core.osu.parsers.beatmap
import core.osu.parsers.beatmap.object.graphic
import core.osu.gameplay.ruleset
import core.osu.gameplay.cursor
import core.osu.gameplay.overlays

pub enum OSUGameplayMode {
	auto
	replay
	player
}

pub struct OSUGameplay {
mut:
	beatmap         &beatmap.Beatmap = unsafe { nil }
	beatmap_audio   &audio.Track     = unsafe { nil }
	beatmap_ruleset &ruleset.Ruleset = unsafe { nil }

	cursor  cursor.ICursorController
	overlay &overlays.GameplayOverlay = unsafe { nil }
}

pub fn (mut osu OSUGameplay) init(mut ctx context.Context, beatmap_lazy &beatmap.Beatmap, mode OSUGameplayMode) {
	// Init renderer
	// Renderer: SGP
	sgp_desc := sgp.Desc{}
	sgp.setup(&sgp_desc)

	if !sgp.is_valid() {
		panic('Failed to init SokolGP: ${sgp.get_error_message(sgp.get_last_error())}')
	}

	// Renderer: Slider
	graphic.init_slider_renderer()

	// Renderer: Skin storage
	skin.bind_context(mut ctx)

	// NOTE: Routine starts here.
	osu.beatmap = beatmap_lazy.load_full_beatmap()
	osu.beatmap.bind_context(mut ctx)
	osu.beatmap.reset() // NOTE: This can be delayed.

	osu.beatmap_audio = audio.new_track(osu.beatmap.get_audio_path())
	osu.beatmap_audio.set_volume(0.2)

	// TODO: Implement replay/auto later.
	match mode {
		.player {
			osu.cursor = cursor.make_player_cursor(mut ctx)
		}
		.auto {
			osu.cursor = cursor.make_auto_cursor(mut ctx, osu.beatmap.objects)
		}
		.replay {
			panic('TODO')
		}
	}

	// FIXME: Ruleset hack.
	mut temp_cursor_hack := [osu.cursor.cursor]
	osu.beatmap_ruleset = ruleset.new_ruleset(mut osu.beatmap, mut temp_cursor_hack)

	// Overlay
	osu.overlay = overlays.new_gameplay_overlay(osu.beatmap_ruleset, osu.cursor.cursor,
		osu.cursor.player, ctx)
}

pub fn (mut osu OSUGameplay) draw(mut ctx context.Context) {
	osu.beatmap.free_slider_attr()

	// Background
	ctx.begin()
	ctx.end()

	// Beatmap & Storyboard
	osu.beatmap.draw()

	ctx.begin_gp()
	osu.overlay.draw()
	osu.cursor.cursor.draw()
	ctx.end_gp_short()
}

pub fn (mut osu OSUGameplay) update(time_ms f64, time_delta f64) {
	// Song
	if time_ms >= settings.global.gameplay.playfield.lead_in_time && !osu.beatmap_audio.playing {
		osu.beatmap_audio.set_position(time_ms - settings.global.gameplay.playfield.lead_in_time)
		osu.beatmap_audio.play()
	}

	// Ruleset
	osu.beatmap_ruleset.mutex.@lock()
	osu.beatmap_ruleset.update_click_for(osu.cursor.cursor, time_ms - settings.global.gameplay.playfield.lead_in_time)
	osu.beatmap_ruleset.update_normal_for(osu.cursor.cursor, time_ms - settings.global.gameplay.playfield.lead_in_time,
		false)
	osu.beatmap_ruleset.update_post_for(osu.cursor.cursor, time_ms - settings.global.gameplay.playfield.lead_in_time,
		false)
	osu.beatmap_ruleset.update(time_ms - settings.global.gameplay.playfield.lead_in_time)
	osu.beatmap_ruleset.mutex.unlock()

	// Beatmap
	osu.beatmap.update(time_ms - settings.global.gameplay.playfield.lead_in_time, 1.0)

	// Cursor
	osu.cursor.update(time_ms - settings.global.gameplay.playfield.lead_in_time, time_delta)

	// Overlay
	osu.overlay.update(time_ms - settings.global.gameplay.playfield.lead_in_time)
}

// Events (Key, Mouse)
pub fn (mut osu OSUGameplay) event_keydown(keycode gg.KeyCode) {
	if !osu.cursor.cursor.manual {
		return
	}

	osu.beatmap_ruleset.mutex.@lock()
	if keycode == .a {
		osu.cursor.cursor.left_button = true
	}

	if keycode == .s {
		osu.cursor.cursor.right_button = true
	}
	osu.beatmap_ruleset.mutex.unlock()
}

pub fn (mut osu OSUGameplay) event_keyup(keycode gg.KeyCode) {
	if !osu.cursor.cursor.manual {
		return
	}

	osu.beatmap_ruleset.mutex.@lock()
	if keycode == .a {
		osu.cursor.cursor.left_button = false
	}

	if keycode == .s {
		osu.cursor.cursor.right_button = false
	}
	osu.beatmap_ruleset.mutex.unlock()
}

pub fn (mut osu OSUGameplay) event_mouse(p_x f32, p_y f32) {
	if !osu.cursor.cursor.manual {
		return
	}

	osu.cursor.cursor.position.x = (p_x - x.resolution.offset.x) / x.resolution.playfield_scale
	osu.cursor.cursor.position.y = (p_y - x.resolution.offset.y) / x.resolution.playfield_scale
}
