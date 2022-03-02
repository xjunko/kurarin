module beatmap

import os
import difficulty
import object

import framework.logging

pub fn parse_beatmap(path string) &Beatmap {
	if !os.exists(path) {
		logging.fatal("Beatmap file: ${path} doesnt exists.")
		exit(1)
	}

	mut lines := os.read_lines(path) or {
		logging.fatal("Failed to read file: ${path}, reason: ${err}")
		exit(1)
	}

	logging.info("Parsing beatmap!")

	mut beatmap := &Beatmap{}
	beatmap.root = os.dir(path)
	beatmap.filename = os.base(path)

	// temp attrs
	mut category := ""
	mut background_done := false

	for mut line in lines {
		if line.trim_space().len == 0 || line.starts_with('//') { continue }

		if temp_category := parse_category(line) {
			category = temp_category
			continue
		}

		match category {
			"General" {
				items := common_parse_with_key_value(line, ":")
				general_beatmap_parser<BeatmapGeneralInfo>(mut beatmap.general, items[0], items[1])
			}

			"Metadata" {
				items := common_parse_with_key_value(line, ":")
				general_beatmap_parser<BeatmapMetadataInfo>(mut beatmap.metadata, items[0], items[1])
			}

			"Difficulty" {
				items := common_parse_with_key_value(line, ":")
				general_beatmap_parser<difficulty.Difficulty>(mut beatmap.difficulty.Difficulty, items[0], items[1])
			}

			"TimingPoints" {
				items := common_parse_with_key_value(line, ",")

				point_time := items[0].f64()
				bpm := items[1].f64()

				mut signature := 4
				mut sample_set := beatmap.timing.last_set
				mut sample_index := 1
				mut sample_volume := 1.0
				mut inherited := false
				mut kiai := false

				if items.len > 2 {
					signature = items[2].int()

					if signature == 0 {
						signature = 4
					}
				}

				if items.len > 3 {
					sample_set = items[3].int()
				}

				if items.len > 4 {
					sample_index = items[4].int()
				}

				if items.len > 5 {
					sample_volume = items[5].f64() / 100
				}

				if items.len > 6 {
					inherited = items[6] == "0"
				}

				if items.len > 7 {
					kiai = (items[7].int() & 1) > 0
				}

				beatmap.timing.add_point(
					point_time, bpm, sample_set, sample_index, sample_volume,
					signature, inherited, kiai
				)
				beatmap.timing.last_set = sample_set
				
			}

			"Events" {
				if (line.starts_with("0") || line.starts_with("Sprite")) && !background_done {
					items := common_parse_with_key_value(line, ",")
					beatmap.general.bg_filename = items[2].replace('"', "")
					background_done = true
					continue
				}

				beatmap.temp_beatmap_sb << line
			}

			"HitObjects" {
				// Calculate difficulty and timing if havent
				if !beatmap.difficulty.calculated {
					beatmap.difficulty.calculate()
					beatmap.timing.calculate()

					//
					beatmap.timing.slider_multiplier = beatmap.difficulty.slider_multiplier
					beatmap.timing.slider_tick_rate = beatmap.difficulty.slider_tick_rate

					//
					logging.info("Beatmap difficulty calculated.")
				}

				mut object := object.make_object(common_parse_with_key_value(line, ","))
				if object.id == -10 { continue }

				beatmap.objects << &object


			}

			else {}
		}
	}

	logging.info("Done parsing beatmap!")

	return beatmap
}

// Utils
pub fn common_parse_with_key_value(line string, split string) []string {
	return line.split(split).map(it.trim_space())
}

pub fn parse_category(line string) ?string {
	if line.starts_with('[') {
		return line.replace('[', '').replace(']', '').trim_space()
	}

	return none
}

pub fn general_beatmap_parser<T>(mut cls T, name string, value string) {
	$for field in T.fields {
		// No attrs defined       // Attrs Defined										// No _SKIP defined in attrs
		if (field.name == name || (field.attrs.len > 0 && field.attrs[0] == name)) && !field.attrs.contains("_SKIP"){
			// V cant do this... for now....... :trolldecai:
			// match field.typ {
			// 	string  { cls.$field.name = value }
			// 	int { cls.$field.name = value.int() }
			// 	f32 { cls.$field.name = value.f32() }
			// 	i64 { cls.$field.name = value.i64() }
			// 	f64 { cls.$field.name = value.f64() }
			// 	else { panic("Type not supported: ${field.typ}")}
			// }

			// This is ugly but itll do for now
			$if field.typ is string {
				cls.$(field.name) = value
			} $else $if field.typ is int {
				cls.$(field.name) = value.int()
			} $else $if field.typ is f32 {
				cls.$(field.name) = value.f32()
			} $else $if field.typ is i64 {
				cls.$(field.name) = value.i64()
			} $else $if field.typ is f64 {
				cls.$(field.name) = value.f64()
			} $else $if field.typ is bool {
				cls.$(field.name) = value == '1'
			} $else {
				panic("Type not supported: ${field.typ}")
			}
		}
	}
}
