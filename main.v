module main

import os
import flag

// osu!
import core.osu.runtime.play_old
import core.osu.runtime.play_new
import core.osu.runtime.constants

// proseka
import core.sekai.runtime.sekai

import framework.logging

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application(constants.game_name)
	fp.version(constants.game_version)
	fp.description("UI is very very very (repeat 100 times) WIP, dont even try it.")
	// fp.limit_free_args(0, 0) or {}

	// Old
	beatmap_path := fp.string("beatmap", `b`, "", "Path to the .osu file.")
	is_playing := fp.bool("play", `p`, false, "Flag for playing in the client.")
	
	// New
	gui_mode := fp.bool("ui", `u`, false, "Very early and experimental UI")

	// Game
	game_type := fp.string("game", `g`, "osu", "Option for game engines. (osu!/sekai)")

	fp.finalize() or {
		logging.error(err.str())
		println(fp.usage())
		return
	}

	// Default to osu! if game is not sekai
	if game_type != "sekai" {
		// Old fallback
		if !gui_mode && beatmap_path.len == 0 {
			println(fp.usage())
			return
		}

		if gui_mode {
			play_new.main()
		} else {
			play_old.main(beatmap_path.replace("\\", ""), is_playing)
		}
	} else {
		sekai.main()
	}
	
}