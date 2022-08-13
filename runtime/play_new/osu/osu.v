module osu

import library.gg

import framework.audio

import core.osu.beatmap

import database


pub struct Osu {
	mut:
		ctx &gg.Context = voidptr(0)

	pub mut:
		g_db &database.OsuDatabase

		current_beatmap 	   &beatmap.Beatmap = voidptr(0)
		current_beatmap_loaded bool

		current_beatmap_audio  &audio.Track = voidptr(0)
		current_beatmap_audio_loaded bool

		current_beatmap_background gg.Image
		current_beatmap_background_loaded bool
}

pub fn (mut osu Osu) init(mut ctx &gg.Context) {
	osu.ctx = ctx
}

pub fn (mut osu Osu) get_current_background() gg.Image {
	if !osu.current_beatmap_background_loaded {
		osu.current_beatmap_background = osu.ctx.create_image(
			osu.get_current_beatmap()
				.get_bg_path()
		)
		osu.current_beatmap_background_loaded = true
	}

	return osu.current_beatmap_background
}

pub fn (mut osu Osu) get_current_audio() &audio.Track {
	if !osu.current_beatmap_audio_loaded || osu.current_beatmap_audio == voidptr(0) {
		osu.current_beatmap_audio = audio.new_track(
			osu.get_current_beatmap()
				.get_audio_path()
		)
	}

	return osu.current_beatmap_audio
}

pub fn (mut osu Osu) get_current_beatmap() &beatmap.Beatmap {
	if !osu.current_beatmap_loaded || osu.current_beatmap == voidptr(0) {
		osu.current_beatmap = osu.g_db.get_random_beatmap()
		osu.current_beatmap_loaded = true
	}

	return osu.current_beatmap
}