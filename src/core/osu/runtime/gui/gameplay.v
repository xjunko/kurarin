module gui

import gg
import sokol.sgl
import sokol.gfx
import mohamedlt.sokolgp as sgp
import framework.audio
import core.osu.x
import core.osu.system.skin
import core.osu.system.player
import core.osu.parsers.beatmap
import core.osu.parsers.beatmap.object.graphic
import core.osu.gameplay.ruleset
import core.osu.gameplay.cursor
import core.common.settings

// Decl
fn C._sapp_glx_swapinterval(int)

// Structs
pub struct GameplayScene {
mut:
	window &GUIWindow

	time_to_start         f64
	time_to_start_reached bool
pub mut:
	beatmap         &beatmap.Beatmap = unsafe { nil }
	beatmap_audio   &audio.Track     = unsafe { nil }
	beatmap_ruleset &ruleset.Ruleset = unsafe { nil }

	cursor cursor.ICursorController
}

pub fn (mut gameplay GameplayScene) init(mut window GUIWindow, beatmap_path string) {
	gameplay.window = unsafe { window }

	window.logs << '${@METHOD}: Initializing gameplay.'

	// HACK: Turn off VSync
	C._sapp_glx_swapinterval(0)

	// Initialize renderers
	// Renderer: SGP
	sgp_desc := sgp.Desc{}
	sgp.setup(&sgp_desc)

	if !sgp.is_valid() {
		panic('Failed to init SokolGP: ${sgp.get_error_message(sgp.get_last_error())}')
	}

	graphic.init_slider_renderer()
	x.force_calculate()
	skin.bind_context(mut gameplay.window.ctx)

	// Start loading beatmap.
	gameplay.beatmap = beatmap.parse_beatmap(beatmap_path, false)
	gameplay.beatmap.bind_context(mut gameplay.window.ctx)
	gameplay.beatmap.reset()

	gameplay.beatmap_audio = audio.new_track(gameplay.beatmap.get_audio_path())

	// Cursor (Auto for now)
	gameplay.cursor = cursor.make_auto_cursor(mut gameplay.window.ctx, gameplay.beatmap.objects)

	mut temp_cursor_hack := [gameplay.cursor.cursor]

	// Ruleset
	gameplay.beatmap_ruleset = ruleset.new_ruleset(mut gameplay.beatmap, mut temp_cursor_hack)
}

pub fn (mut gameplay GameplayScene) update(time_ms f64, time_delta f64) {
	// Audio
	if time_ms >= settings.global.gameplay.playfield.lead_in_time && !gameplay.time_to_start_reached {
		gameplay.time_to_start_reached = true

		gameplay.beatmap_audio.set_volume(0.3)
		gameplay.beatmap_audio.set_position(time_ms - settings.global.gameplay.playfield.lead_in_time)
		gameplay.beatmap_audio.play()
	}

	// Ruleset
	gameplay.beatmap_ruleset.update_click_for(gameplay.cursor.cursor, time_ms - settings.global.gameplay.playfield.lead_in_time)
	gameplay.beatmap_ruleset.update_normal_for(gameplay.cursor.cursor, time_ms - settings.global.gameplay.playfield.lead_in_time,
		false)
	gameplay.beatmap_ruleset.update_post_for(gameplay.cursor.cursor, time_ms - settings.global.gameplay.playfield.lead_in_time,
		false)
	gameplay.beatmap_ruleset.update(time_ms - settings.global.gameplay.playfield.lead_in_time)
	gameplay.beatmap.update(time_ms - settings.global.gameplay.playfield.lead_in_time,
		0.0)

	// Cursor
	gameplay.cursor.update(time_ms - settings.global.gameplay.playfield.lead_in_time)
	gameplay.cursor.cursor.update(time_ms - settings.global.gameplay.playfield.lead_in_time,
		time_delta)
}

pub fn (mut gameplay GameplayScene) draw() {
	gameplay.beatmap.free_slider_attr()

	// Noop
	gameplay.window.ctx.begin()
	gameplay.window.ctx.end()

	// Game
	gameplay.beatmap.draw()

	// Cursor
	gameplay.window.ctx.begin_gp()
	gameplay.cursor.cursor.draw()

	gameplay.window.ctx.begin()

	// Draw logs (The last 32)
	for i, log in gameplay.window.logs#[-32..] {
		gameplay.window.ctx.draw_rect_filled(0, i * 16, gameplay.window.ctx.text_width(log),
			16, gg.Color{0, 0, 0, 255})
		gameplay.window.ctx.draw_text(0, i * 16, log, color: gg.Color{255, 255, 255, 255})
	}

	// Pass
	gfx.begin_default_pass(graphic.global_renderer.pass_action, int(settings.global.window.width),
		int(settings.global.window.height))
	gameplay.window.ctx.end_gp()
	sgl.draw()
	gfx.end_pass()

	gfx.commit()
}
