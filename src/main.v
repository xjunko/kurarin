module main

import os
import flag
import framework.logging
import core.common.settings
import core.common.constants
import core.osu.runtime
import core.osu.runtime.gui
import core.basic.runtime as basic

const _ = settings.global

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application(constants.game_name)
	fp.version(constants.game_version)

	// Old
	beatmap_path := fp.string('beatmap', `b`, '', 'Path to the .osu file.')
	replay_path := fp.string('replay', `r`, '', 'Path to the .osr file.')
	is_playing := fp.bool('play', `p`, false, 'Enable to play the beatmap.')

	// Game
	game_type := fp.string('game', `g`, 'osu!gui', 'Option for game engines. [osu!, osu!gui] (Other modes is deprecated.)')

	fp.finalize() or {
		logging.error(err.str())
		println(fp.usage())
		return
	}

	match game_type {
		'osu!gui' {
			gui.run(os.args)
		}
		'osu', 'osu!' {
			if beatmap_path.len == 0 {
				println(fp.usage())
				return
			}

			runtime.run(beatmap_path.replace('\\', ''), replay_path.replace('\\', ''),
				is_playing)
		}
		'basic', 'b' {
			basic.run()
		}
		else {
			logging.error('Invalid game_type: ${game_type}')
			return
		}
	}
}
