module beatmap

import os
import math
import object

import game.math.difficulty

pub fn parse_header(line string) string {
	if line.starts_with('[') {
		return line.trim_space().replace(']', '').replace('[', '')
	}

	return ''
}

pub fn parse_commas(line string) []string {
	return line.trim_space().split(',')
}

pub fn parse_k_v(line string, delimiter string, limit int) []string {
	mut result := line.split_nth(delimiter, limit)
	for i, value in result {
		result[i] = value.trim_space().to_lower()
	}

	return result
}

pub fn parse_beatmap(path string) &Beatmap {
	mut beatmap := &Beatmap{
		root: os.dir(path),
		filename: os.base(path)
	}
	beatmap.sb_extra << '[Events]\n'

	mut lines := os.read_lines(path) or { panic(err) }
	mut current_category := ''
	
	//
	mut combo_index := 1
	mut color_index := 1

	for line in lines {
		if line.trim_space().len == 0 || line.starts_with('//') { continue }

		category := parse_header(line)
		if category.len > 0 {
			current_category = category
			continue
		}

		match current_category {
			'General' {
				items := parse_k_v(line, ":", 2)
				parse_common_struct_generic_bullshit<BeatmapGeneralInfo>(mut beatmap.general, items[0], items[1])
			}

			'Difficulty' {
				items := parse_k_v(line, ":", 2)
				parse_common_struct_generic_bullshit<difficulty.DifficultyInfo>(mut beatmap.difficulty, items[0], items[1])
			}

			"Events" {
				if (line.starts_with("0") || line.starts_with("Sprite")) && beatmap.background.len == 0{
					items := parse_k_v(line, ",", -1)
					beatmap.background = items[2].replace('"', '')
				}

				// add to temp
				beatmap.sb_extra << line
			}

			'TimingPoints' {
				items := parse_k_v(line, ",", -1)
				mut vals := []f32{}

				for item in items { vals << item.f32() }
				beatmap.timing.add(vals)
			}

			'Colours' {
				items := parse_k_v(line, ":", 2)
				mut colors := []f64{}

				for value in items[1].split(",") {
					colors << value.f64()
				}

				beatmap.colors << colors
			}

			'HitObjects' {
				if !beatmap.difficulty.created {
					// Make difficulty and timing
					beatmap.difficulty_math = beatmap.difficulty.make_difficulty()
					beatmap.timing.slider_multiplier = beatmap.difficulty_math.slider_multiplier
					beatmap.timing.slider_tick_rate = beatmap.difficulty_math.slider_tick_rate
					beatmap.timing.process()
				}

				// Some color index fallback cuz its not completed
				if beatmap.colors.len == 0 {
					beatmap.colors << [f64(26), 116, 242]
					beatmap.colors << [f64(164), 32, 240]
					beatmap.colors << [f64(37), 185, 239]
					beatmap.colors << [f64(23), 209, 116]
					beatmap.colors << [f64(255), 75, 255]
				}

				combo_index++		
				
				items := parse_commas(line)
				mut object := object.make_hitobject(id: beatmap.objects.len, items: items, diff: beatmap.difficulty_math, timing: beatmap.timing, color: beatmap.colors[color_index % beatmap.colors.len])
				object.combo_index = combo_index

				if object.is_new_combo {
					combo_index = 1
					color_index++
				}				

				beatmap.objects << object
			}
			else { }
		}
	}


	return beatmap
}