module beatmap

import object
import timing

// what da fawgggg
// source: https://github.com/NonSpicyBurrito/sonolus-pjsekai-engine/blob/d2a3c6bda1ef43502e77dcc39cb6e965f86cec7e/src/lib/sus/analyze.ts#L3
/*
	`InternalBeatmap`: Contains internal values thats important on parse time
	`Beatmap`: Light wrapper around `InternalBeatmap` to render objects
*/

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

pub struct RawObject {
	pub mut:
		tick f64
		value string
}
//

[heap] // HACK
pub struct InternalBeatmap {
	mut:
		// Everything Internal
		// This fucking shit is awful, but its important for parsing the fucking thing
		lines   []Line
		measure []MeasureChange
		meta    map[string]string
		
		bpms map[string]f64
		bpm_changes []&RawObject
		tap_notes []&object.NoteObject
		directional_notes []&object.NoteObject

		stream map[string][]&object.NoteObject
		slides [][]&object.NoteObject
		slides2 []string

		bars timing.Bars
		timings timing.Timing

		objects_i int
		flicks_direction map[string]int

	pub mut:
		// Surface level stuff
		notes []&object.NoteObject
		flicks []&object.FlickObject
		sliders []&object.SliderObject
}

// Resolver
pub fn (mut beatmap InternalBeatmap) resolve_object_time() {
	for mut note in beatmap.notes {
		time := beatmap.to_time(note.tick)
		note.time.start = time
		note.time.end = time
	}
}

// Time converters
pub fn (mut beatmap InternalBeatmap) to_tick(measure f64, p f64, q f64) f64 {
	return beatmap.bars.to_tick(measure, p, q)
}

pub fn (mut beatmap InternalBeatmap) to_time(tick f64) f64 {
	return beatmap.timings.to_time(tick)
}