module gameplay

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

pub struct OSUGameplay {
mut:
	beatmap         &beatmap.Beatmap = unsafe { nil }
	beatmap_audio   &audio.Track     = unsafe { nil }
	beatmap_ruleset &ruleset.Ruleset = unsafe { nil }
}

pub fn (mut osu OSUGameplay) init(mut ctx context.Context, beatmap_lazy &beatmap.Beatmap) {
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
}

pub fn (mut osu OSUGameplay) draw(mut ctx context.Context) {
	osu.beatmap.free_slider_attr()

	ctx.begin()
	ctx.end()

	osu.beatmap.draw()
}

pub fn (mut osu OSUGameplay) update(time_ms f64, time_delta f64) {
	if time_ms >= settings.global.gameplay.playfield.lead_in_time && !osu.beatmap_audio.playing {
		osu.beatmap_audio.set_position(time_ms - settings.global.gameplay.playfield.lead_in_time)
		osu.beatmap_audio.play()
	}

	osu.beatmap.update(time_ms - settings.global.gameplay.playfield.lead_in_time, 1.0)
}
