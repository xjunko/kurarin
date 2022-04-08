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
		video        Video = make_video_settings()
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
		logging.info("Please change your settings.json file (if you wanted to), then run the program again.")
		settings.save()
		exit(1)
	} else {
		logging.info("settings.json found, loading.")
		crap := os.read_file('settings.json') or { panic(err) }
		settings = json.decode(Settings, crap) or { panic(err) }
	}

	// Fix some weird stuff just incase
	settings.gameplay.auto_tag_cursors = math.max(1, settings.gameplay.auto_tag_cursors)

	// Also save again, this way new shit can just get append into the json
	settings.save()

	// Post-Fix
	settings.gameplay.lead_in_time = math.max(1.0, settings.gameplay.lead_in_time)
	settings.gameplay.lead_in_time *= 1000.0

	// unepic global hack
	mut g_settings := global
	replace_attribute_from<Settings>(mut g_settings, mut settings)
}

// Greatest hack of all time
fn replace_attribute_from<T>(mut from T, mut with T) {
	$for field in T.fields {
		from.$(field.name) = with.$(field.name)
	}
}