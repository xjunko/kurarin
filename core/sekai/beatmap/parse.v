module beatmap

import os
import regex

import framework.logging

import object
import timing

// Factory
pub fn parse_beatmap(path string) &Beatmap {
	mut bmap := &Beatmap{}
	bmap.analyze(path)

	bmap.resolve_object_time()
	bmap.resolve_note_sprite()

	return bmap
}

// Parse
pub fn (mut beatmap Beatmap) analyze(path string) {
	// losing my mind with these variable names
	mut sus := os.read_lines(path) or { panic("Failed to read path: ${err}") }

	// filter out crap
	sus = sus
		.map(it.trim_space())
		.filter(it.starts_with("#"))

	// basic reading
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

	// pass two, this is where everything becomes retarded
	for index, line in beatmap.lines {
		if line.header.len != 5 { continue }
		if !line.header.ends_with("02") { continue }

		measure := 
			line.header[0 .. 3].f64() 
			+ retarded_javascript_find<MeasureChange>(beatmap.measure, index).b

		beatmap.barlengths << BarLength{
			measure: measure,
			length: line.data.f64()
		}

	}

	// ticks pass
	mut ticks := 0.0

	mut temp_bars := beatmap.barlengths
	temp_bars.sort(a.measure < b.measure)
	
	for i, bar in temp_bars {
		if i > 0 {
			prev := temp_bars[i - 1]
			ticks += (bar.measure - prev.measure) * prev.length * ticks_per_beat
		}

		beatmap.bars << Bar{
			measure: bar.measure,
			ticks_per_measure: bar.length * ticks_per_beat,
			ticks: ticks
		}
	}

	beatmap.bars = beatmap.bars.reverse()

	// objects pass
	for index, line in beatmap.lines {
		measure_offset := retarded_javascript_find(beatmap.measure, index).b

		// BPM
		if line.header.len == 5 && line.header.starts_with("BPM") {
			beatmap.bpms[line.header[3 .. ]] = line.data.f64()
			continue
		}

		// BPM Change
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
			logging.info("${@MOD}: TODO STREAM")
			continue
		}

		// Directional Notes
		if line.header.len == 5 && line.header[3] == `5` {
			logging.info("${@MOD}: TODO DIRECTIONALS")
			continue
		}
	}

	// temporary
	beatmap.tap_notes.sort(a.tick < b.tick)
	mut removed_duplicates := []object.NoteObject{}

	for note in beatmap.tap_notes {
		if note !in removed_duplicates {
			removed_duplicates << note
		}
	}
	beatmap.tap_notes = removed_duplicates
	//

	
	mut temp_timings := beatmap.bpm_changes
		.map(timing.TimingPoint{tick: it.tick, bpm: beatmap.bpms[it.value] or { 0 }})
	
	beatmap.timings.resolve_timing(temp_timings)
}

// Converters
pub fn (mut beatmap Beatmap) to_raw_objects(line Line, measure_offset f64) []RawObject {
	mut re := regex.regex_opt(r".{2}") or { panic("${@METHOD}: ${err}") }
	measure := line.header[0 .. 3].f64() + measure_offset

	data := re.find_all_str(line.data)

	return data.map(
		RawObject{
			tick: [f64(0xDEAD), beatmap.to_tick(measure, data.index(it), data.len)][int(it != "00")],
			value: it
		}
	).filter(
		it.tick != f64(0xDEAD)
	)
}

pub fn (mut beatmap Beatmap) to_note_objects(line Line, measure_offset f64) []object.NoteObject {
	lane := line.header[4].ascii_str().int()

	return beatmap.to_raw_objects(line, measure_offset)
		.map(object.NoteObject{
			tick: it.tick,
			lane: f64(lane),
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