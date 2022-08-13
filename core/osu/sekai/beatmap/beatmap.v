module beatmap

import os
import regex

import framework.math.time

// god i fucking hate typescript/javascript
// source: https://github.com/NonSpicyBurrito/sonolus-pjsekai-engine/blob/d2a3c6bda1ef43502e77dcc39cb6e965f86cec7e/src/lib/sus/analyze.ts#L3

pub const (
		ticks_per_beat = 480.0
		ticks_per_hidden = ticks_per_beat / 2.0
)

// Structs
pub struct Line {
	pub mut:
		header string
		data string
}

pub struct MeasureChange {
	pub mut:
		a f64
		b f64
}

pub struct BarLength {
	pub mut:
		measure f64
		length f64
}

pub struct Bar {
	pub mut:
		measure f64
		ticks_per_measure f64
		ticks f64
}

pub struct RawObject {
	pub mut:
		tick f64
		value string
}

// Every note object inherit this class
pub struct NoteGameObject {
	pub mut:
		time time.Time
}

pub struct NoteObject {
	NoteGameObject

	pub mut:
		tick f64
		lane f64
		width f64
		typ int
}

pub struct Timing {
	pub mut:
		tick f64
		bpm f64
		time f64
}
//

pub struct Beatmap {
	pub mut:
		lines   []Line
		measure []MeasureChange
		bars []Bar
		barlengths []BarLength
		meta    map[string]string
		
		bpms map[string]f64
		bpm_changes []RawObject
		tap_notes []NoteObject
		directional_notes []NoteObject
		stream map[string]NoteObject
		
		timings []Timing

	// pub mut:
		
}

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
			// println("TODO::STREAM")
			continue
		}

		// Directional Notes
		if line.header.len == 5 && line.header[3] == `5` {
			// println("DIRECTIONAl")
			continue
		}
	}

	// temporary
	beatmap.tap_notes.sort(a.tick < b.tick)
	mut removed_duplicates := []NoteObject{}

	for note in beatmap.tap_notes {
		if note !in removed_duplicates {
			removed_duplicates << note
		}
	}
	beatmap.tap_notes = removed_duplicates
	//

	mut time := 0.0
	mut temp_timings := beatmap.bpm_changes
		.map(Timing{tick: it.tick, bpm: beatmap.bpms[it.value] or { 0 }})
	
	for i, timing in temp_timings {
		if i > 0 {
			prev := temp_timings[i - 1]
			time += ((timing.tick - prev.tick) * 60.0) / ticks_per_beat / prev.bpm
		}

		beatmap.timings << Timing{
			tick: timing.tick,
			bpm: timing.bpm,
			time: time
		}
	}
}

// Resolver
pub fn (mut beatmap Beatmap) resolve_object_time() {
	for mut note in beatmap.tap_notes {
		time := beatmap.to_time(note.tick)
		note.time.start = time
		note.time.end = time
	}
}

// Time converters

pub fn (mut beatmap Beatmap) to_tick(measure f64, p f64, q f64) f64 {
	mut bar := Bar{ticks: 0xDEAD}

	for bar_to_find in beatmap.bars {
		if measure >= bar_to_find.measure {
			bar = bar_to_find
			break
		}
	}

	if bar.ticks == 0xDEAD { panic("Invalid bar") }

	return bar.ticks + 
		(measure - bar.measure) * bar.ticks_per_measure +
		(p * bar.ticks_per_measure) / q
}

pub fn (mut beatmap Beatmap) to_time(tick f64) f64 {
	mut timing := Timing{bpm: 0xDEAD}

	for timing_to_find in beatmap.timings {
		if tick >= timing_to_find.tick {
			timing = timing_to_find
			break
		}
	}

	if timing.bpm == 0xDEAD { panic("@FUNCTION: Invalid timing") }

	return (timing.time +
		((tick - timing.tick) * 60.0) / ticks_per_beat / timing.bpm) * 1000.0
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

pub fn (mut beatmap Beatmap) to_note_objects(line Line, measure_offset f64) []NoteObject {
	lane := line.header[4].ascii_str().int()

	return beatmap.to_raw_objects(line, measure_offset)
		.map(NoteObject{
			tick: it.tick,
			lane: f64(lane),
			width: it.value[1].ascii_str().int(),
			typ: it.value[0].ascii_str().int()
		})
}

// utils
fn retarded_javascript_find<T>(array []T, index int) T {
	for array_index, _ in array {
		if array_index <= index {
			return array[array_index]
		}
	}

	return T{}
}

// fn retarded_javascript_find_field<T>(array []T, value f64, field_name string) f64 {
// 	for obj in array {
// 		$for field in T.fields {
// 			if field.name == field_name {
// 				return (obj.$(field.name)).str().f64()
// 			}
// 		}
// 	}

// 	return 0.0
// }

// factory
pub fn parse_beatmap(path string) &Beatmap {
	mut bmap := &Beatmap{}
	bmap.analyze(path)
	bmap.resolve_object_time()

	return bmap
}