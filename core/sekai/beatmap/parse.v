module beatmap

import os
import math
import regex

// import framework.logging

import object
import timing

// Factory
pub fn parse_beatmap(path string) &InternalBeatmap {
	mut bmap := &InternalBeatmap{}
	bmap.analyze(path)

	bmap.resolve_object_time()
	bmap.resolve_objects()

	return bmap
}

// Parse
pub fn (mut beatmap InternalBeatmap) analyze(path string) {
	// losing my mind with these variable names
	mut sus := os.read_lines(path) or { panic("Failed to read path: ${err}") }

	// filter out crap
	sus = sus
		.map(it.trim_space())
		.filter(it.starts_with("#"))

	// Basic reading, verified.
	for line in sus {
		is_line := line.contains(":")

		what_to_find := [" ", ":"][int(is_line)]
		index := line.index(what_to_find) or { 0xDEAD }

		if index == 0xDEAD {
			continue
		}

		left := line.substr(1, index).trim_space()
		right := line.substr(index + 1, line.len).trim_space()

		if is_line {
			beatmap.lines << Line{
				header: left,
				data: right
			}
		} else if left == "MEASUREBS" {
			beatmap.measure << MeasureChange{
				f64(beatmap.lines.len),
				right.f64()
			}
		} else {
			beatmap.meta[left] = right
		}
	}


	// pass two, this is where everything becomes retarded, verified.
	for index, line in beatmap.lines {
		if line.header.len != 5 { continue }
		if !line.header.ends_with("02") { continue }

		measure := 
			line.header[0 .. 3].f64() 
			+ retarded_javascript_find<MeasureChange>(beatmap.measure, index).b

		beatmap.bars.add_bar_length(timing.BarLength{
			measure: measure,
			length: line.data.f64()
		})

	}
	// Bars (ticks) pass, verified.
	beatmap.bars.resolve_bars()

	// objects pass
	for index, line in beatmap.lines {
		measure_offset := retarded_javascript_find(beatmap.measure, index).b

		// BPM, verified.
		if line.header.len == 5 && line.header.starts_with("BPM") {
			beatmap.bpms[line.header[3 .. ]] = line.data.f64()
			continue
		}

		// BPM Change, verified.
		if line.header.len == 5 && line.header.ends_with("08") {
			beatmap.bpm_changes << beatmap.to_raw_objects(line, measure_offset)
			continue
		}

		// Tap Notes
		if line.header.len == 5 && line.header[3] == `1` {
			beatmap.tap_notes << beatmap.to_note_objects(line, measure_offset)
			continue
		}

		// Tap Notes (stream)
		if line.header.len == 6 && line.header[3] == `3` {
			channel := line.header[5].ascii_str()
			
			if channel !in beatmap.stream {
				beatmap.stream[channel] = []&object.NoteObject{}
			}

			beatmap.stream[channel] << beatmap.to_note_objects(line, measure_offset)

			continue
		}

		// Directional Notes
		if line.header.len == 5 && line.header[3] == `5` {
			beatmap.directional_notes << beatmap.to_note_objects(line, measure_offset)
			continue
		}
	}

	// Slides
	// Scuffed but whatever
	for mut slide in beatmap.stream.values() {
		beatmap.slides <<  beatmap.to_slides(mut slide)
	}

	// TODO: Move this to somewhere else
	for slide in beatmap.slides {
		for note in slide {
			key := get_key(note.BaseNoteObject)

			match note.typ {
				5 { beatmap.slides2 << key }
				else {}
			}
		}
	}

	// Timings
	beatmap.tap_notes.sort(a.tick < b.tick)
	mut removed_duplicates := []&object.NoteObject{}

	for note in beatmap.tap_notes {
		if note !in removed_duplicates {
			removed_duplicates << note
		}
	}

	beatmap.tap_notes = removed_duplicates

	mut temp_timings := beatmap.bpm_changes
		.map(timing.TimingPoint{tick: it.tick, bpm: beatmap.bpms[it.value] or { 0 }})
	
	beatmap.timings.resolve_timing(temp_timings)

	// TODO: Move this to somewhere else
	for tap_note in beatmap.directional_notes {
		key := get_key(tap_note.BaseNoteObject)

		match tap_note.typ {
			1 {
				beatmap.flicks_direction[key] = -1
			}

			3 {
				beatmap.flicks_direction[key] = 0
			}

			4 {
				beatmap.flicks_direction[key] = 1
			}

			else {}
		}
	}
}

pub fn (mut beatmap InternalBeatmap) resolve_objects() {
	mut valid_tap_notes := []&object.NoteObject{}
	mut valid_flick_notes := []&object.FlickObject{}
	mut valid_slider_notes := []&object.SliderObject{}

	for i := 0; i < beatmap.tap_notes.len; i++ {
		key := get_key(beatmap.tap_notes[i].BaseNoteObject)

		// Slider checks
		if key in beatmap.slides2 || beatmap.tap_notes[i].typ !in [1, 2] {
			continue // Not our note, ignore.
		}

		// Flicker
		if key in beatmap.flicks_direction {
			valid_flick_notes << &object.FlickObject{
				BaseNoteObject: beatmap.tap_notes[i].BaseNoteObject
				direction: beatmap.flicks_direction[key]
			}

			continue
		}

		// Normal notes
		valid_tap_notes << beatmap.tap_notes[i]
	}

	// Slider is retarded
	// so it has its own pass
	mut i_slide_keys := []string{}

	for i := 0; i < beatmap.slides.len; i++ {
		mut key := beatmap.slides[i].map(get_key(it.BaseNoteObject)).join("|")

		if key in i_slide_keys {
			continue
		} else {
			i_slide_keys << key
		}

		// Find the start note
		mut found := false
		mut start_note := &object.NoteObject{typ: 0xDEAD}

		for j := 0; j < beatmap.slides[i].len; j++ {
			if beatmap.slides[i][j].typ in [1, 2] {
				start_note = beatmap.slides[i][j]
				found = true
				break
			}
		}

		if !found { continue } // i dont fucking know

		mut is_critical := false
		mut min_hidden_tick := math.floor(
			start_note.tick / ticks_per_hidden + 1
		) * ticks_per_hidden

		_ := min_hidden_tick + int(is_critical) // HACK: shut the fuck up v

		// Slider
		mut slider_note := &object.SliderObject{}

		// Get start, end slider head fornow
		for j := 0; j < beatmap.slides[i].len; j++ {
			key = get_key(beatmap.slides[i][j].BaseNoteObject)

			time := beatmap.to_time(beatmap.slides[i][j].tick)
			beatmap.slides[i][j].time.start = time
			beatmap.slides[i][j].time.end = time

			match beatmap.slides[i][j].typ {
				1 {
					// Start
					beatmap.slides[i][j].is_slider_start = true
					slider_note.BaseNoteObject = beatmap.slides[i][j].BaseNoteObject
					slider_note.start = beatmap.slides[i][j]
				}

				2 {
					// End
					beatmap.slides[i][j].is_slider_end = true
					slider_note.end = beatmap.slides[i][j]
				}

				3 {
					// Tick
					beatmap.slides[i][j].is_slider_path = true
					slider_note.ticks << beatmap.slides[i][j]
				}

				else {}
			}
		}

		valid_slider_notes << slider_note
	}
}

// Utils
pub fn get_key(n object.BaseNoteObject) string {
	return "${n.lane}-${n.tick}"
}

// Converters
pub fn (mut beatmap InternalBeatmap) to_raw_objects(line Line, measure_offset f64) []&RawObject {
	mut re := regex.regex_opt(r".{2}") or { panic("${@METHOD}: ${err}") }
	measure := line.header[0 .. 3].f64() + measure_offset

	data := re.find_all_str(line.data)

	mut ret := []&RawObject{}

	for i, current_data in data {
		if current_data != "00" {
			ret << &RawObject{
				tick: beatmap.to_tick(measure, i, data.len),
				value: current_data
			}
		}
	}

	return ret
}

pub fn (mut beatmap InternalBeatmap) to_slides(mut stream []&object.NoteObject) [][]&object.NoteObject {
	mut slides := [][]&object.NoteObject{}

	mut current := []&object.NoteObject{}
	mut reset := false
	
	stream.sort(a.tick < b.tick)

	for note in stream {
		if reset {
			slides << current
			current = []&object.NoteObject{}
			reset = false
		}

		current << note

		if note.typ == 2 {
			reset = true
		}
	}

	return slides
}

pub fn (mut beatmap InternalBeatmap) to_note_objects(line Line, measure_offset f64) []&object.NoteObject {
	lane := line.header[4].ascii_str().int()

	return beatmap.to_raw_objects(line, measure_offset)
		.map(&object.NoteObject{
			tick: it.tick,
			lane: 11 - f64(lane),
			width: it.value[1].ascii_str().int(),
			typ: it.value[0].ascii_str().int()
		})
}

// Utils
fn retarded_javascript_find<T>(array []T, index int) T {
	for array_index, _ in array {
		if array_index <= index {
			return array[array_index]
		}
	}

	return T{}
}