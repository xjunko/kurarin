module settings

import os
import math
import json

import framework.logging

pub const (
	global = &Settings{} // disgusting global hack
)

pub struct Settings {
	pub mut:
		window   	 Window = make_window_settings()
		gameplay 	 Gameplay = make_gameplay_settings()
		miscellaneous Miscellaneous = make_miscellaneous_settings()
}

pub fn (mut settings Settings) save() {
	os.write_file("settings.json", json.encode_pretty(settings)) or {
		panic("$err")
	}
}

fn init() {
	logging.debug("Trying to load settings")

	mut settings := Settings{}

	if !os.exists("settings.json") {
		logging.info("No settings.json file found, creating one.")
		settings.save()
		exit(1)
	} else {
		logging.info("settings.json found, loading.")
		crap := os.read_file('settings.json') or { panic(err) }
		settings = json.decode(Settings, crap) or { panic(err) }
	}

	// Also save again, this way new shit can just get append into the json
	settings.save()

	// Post-Fix
	settings.gameplay.lead_in_time = math.max(1.0, settings.gameplay.lead_in_time)
	settings.gameplay.lead_in_time *= 1000.0

	if settings.window.record {
		settings.gameplay.disable_hitsound = true // TODO: remove this once we got BASS pipe to ffmpeg
	}

	// lmaooo
	mut g_settings := global
	g_settings.window = settings.window
	g_settings.gameplay = settings.gameplay
	g_settings.miscellaneous = settings.miscellaneous
}