module audio

import os
import game.skin
import game.settings

const (
	samples = [
		["normal-hitnormal", "soft-hitnormal", "drum-hitnormal"],
		["normal-hitwhistle", "soft-hitwhistle", "drum-hitwhistle"],
		["normal-hitfinish", "soft-hitfinish", "drum-hitfinish"],
		["normal-hitclap", "soft-hitclap", "drum-hitclap"]
	]
)

pub fn play_osu_sample(sample int, sample_set int) {
	if settings.gameplay.disable_hitsound { return }

	skin_root := skin.get_skin().fallback
	play(path: os.join_path(skin_root, '${samples[0][sample_set - 1]}.wav'))

	if (sample & 2) > 0 {
		play(path: os.join_path(skin_root, '${samples[1][sample_set - 1]}.wav'))
	}
	if (sample & 4) > 0 {
		play(path: os.join_path(skin_root, '${samples[2][sample_set - 1]}.wav'))
	}
	if (sample & 8) > 0 {
		play(path: os.join_path(skin_root, '${samples[3][sample_set - 1]}.wav'))
	}
}
