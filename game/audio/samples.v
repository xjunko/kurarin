module audio

import os
import game.settings

import framework.audio
import framework.logging

const (
	global_sample = &GameSamples{}
	set_ids = {
		"normal": 1,
		"soft": 2,
		"drum": 3,
	}
	hitsound_names = {
		"hitnormal":     1,
		"hitwhistle":    2,
		"hitfinish":     3,
		"hitclap":       4,
		"slidertick":    5,
		"sliderslide":   6,
		"sliderwhistle": 7,
	}
)

pub struct GameSamples {
	pub mut:
		base     	 [3][7]audio.Sample
		beatmap 	 [3][7]map[int]audio.Sample
		cache        map[string]audio.Sample
		skin_path    string
		beatmap_path string
}

pub fn (mut sample GameSamples) load_base_sample() {
	mut filename := [3][7]string{}

	filename[0][0] = "normal-hitnormal"
	filename[0][1] = "normal-hitwhistle"
	filename[0][2] = "normal-hitfinish"
	filename[0][3] = "normal-hitclap"
	filename[0][4] = "normal-slidertick"
	filename[0][5] = "normal-sliderslide"
	filename[0][6] = "normal-sliderwhistle"

	filename[1][0] = "soft-hitnormal"
	filename[1][1] = "soft-hitwhistle"
	filename[1][2] = "soft-hitfinish"
	filename[1][3] = "soft-hitclap"
	filename[1][4] = "soft-slidertick"
	filename[1][5] = "soft-sliderslide"
	filename[1][6] = "soft-sliderwhistle"

	filename[2][0] = "drum-hitnormal"
	filename[2][1] = "drum-hitwhistle"
	filename[2][2] = "drum-hitfinish"
	filename[2][3] = "drum-hitclap"
	filename[2][4] = "drum-slidertick"
	filename[2][5] = "drum-sliderslide"
	filename[2][6] = "drum-sliderwhistle"

	// Append skin path
	for x in 0 .. 3 {
		for y in 0 .. 7 {
			for format in ["mp3", "wav", "ogg"] {
				if os.exists(os.join_path(sample.skin_path, filename[x][y] + ".${format}")) {
					sample.base[x][y] = audio.new_sample(os.join_path(sample.skin_path, filename[x][y]) + ".${format}")
					break
				}
			}
		}
	}

}

pub fn (mut sample GameSamples) load_beatmap_sample() {
	os.walk(sample.beatmap_path, fn (path string) {
		// URGH
		split_before_digit := fn (text string) []string {
			// TODO: 3am code; this is retarded, find a better way
			numbers := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
			for i, charac in text {
				if charac.str_escaped() in numbers {
					return [text[..i], text[i..]]
				}
			}

			return [text]
		}	
		
		// Skip folders ?
		if os.is_dir(path) { return }

		filename := os.base(path)

		// Not a supported audio file, skip
		if !filename.ends_with(".wav") && !filename.ends_with(".mp3") && !filename.ends_with(".ogg") {
			return
		}

		raw_name := filename.replace(".wav", "").replace(".ogg", "").replace(".mp3", "")

		items := raw_name.split("-")

		// Is a hitsound file
		if items.len == 2 {
			// Ignore
			if items[0] !in set_ids {
				logging.debug("The fuck: ${items[0]} - hitsound walk")
				return
			}

			current_set_id := set_ids[items[0]]
			sub_items := split_before_digit(items[1])
			mut hitsound_index := 1

			if sub_items.len > 1 {
				hitsound_index = sub_items[1].int()
			}

			if sub_items[0] !in hitsound_names {
				return
			}

			current_hitsound_id := hitsound_names[sub_items[0]]


			// Save to sample
			mut g_sample := get_global_sample()
			
			// Re-Init the dict again (segmentation error w/o this)
			if g_sample.beatmap[current_set_id - 1][current_hitsound_id - 1].len == 0 {
				g_sample.beatmap[current_set_id - 1][current_hitsound_id - 1] = map[int]audio.Sample{}
			}
	
			g_sample.beatmap[current_set_id - 1][current_hitsound_id - 1][hitsound_index] = audio.new_sample(path)
		}
	})
}

pub fn play_sample(sample_set int, _addition_set int, hitsound int, index int, volume f64) {
	if settings.global.audio.disable_samples { return }

	mut addition_set := _addition_set

	if addition_set == 0 {
		addition_set = sample_set
	}

	// Normal
	if hitsound & 1 > 0 || hitsound == 0 {
		play_sample_internal(sample_set, 0, index, volume)
	}

	// Whistle
	if hitsound & 2 > 0 {
		play_sample_internal(addition_set, 1, index, volume)
	}

	// Finish
	if hitsound & 4 > 0 {
		play_sample_internal(addition_set, 2, index, volume)
	}

	// Clap
	if hitsound & 8 > 0 {
		play_sample_internal(addition_set, 3, index, volume)
	}
}

pub fn play_sample_internal(_sample_set int, hitsound_index int, index int, volume f64) {
	mut sample_set := _sample_set

	if sample_set == 0 {
		sample_set = 2
	} else if sample_set < 0 || sample_set > 3 {
		sample_set = 1
	}

	mut g_sample := global_sample
	if global_sample.beatmap[sample_set - 1][hitsound_index].len > 0 && index in global_sample.beatmap[sample_set -1][hitsound_index] && !settings.global.audio.ignore_beatmap_samples {
		g_sample.beatmap[sample_set - 1][hitsound_index][index].play_volume(f32(volume))
	} else {
		g_sample.base[sample_set - 1][hitsound_index].play_volume(f32(volume))
	}
}



// Internal
fn get_global_sample() &GameSamples {
	mut sample := global_sample
	return sample
}


pub fn init_samples(skin_path string, beatmap_path string) {
	mut sample := get_global_sample()
	sample.skin_path = skin_path
	sample.beatmap_path = beatmap_path
	sample.load_base_sample()
	sample.load_beatmap_sample()
}

pub fn get_sample(name string) audio.Sample {
	mut sample := get_global_sample()

	if name.to_lower() !in sample.cache {
		for format in ["mp3", "wav", "ogg"] {
			path := os.join_path(sample.skin_path, name) + ".${format}"

			if os.exists(path) {
				sample.cache[name.to_lower()] = audio.new_sample(path)
			}
		}
	}

	// FIXME: im not sure how to handle this exactly
	return sample.cache[name.to_lower()] or { audio.Sample{} }
}
