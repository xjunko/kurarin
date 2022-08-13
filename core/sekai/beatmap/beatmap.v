module beatmap

import framework.math.time

import object
import timing

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

pub struct RawObject {
	pub mut:
		tick f64
		value string
}
//

pub struct Beatmap {
	pub mut:
		lines   []Line
		measure []MeasureChange
		meta    map[string]string
		
		bpms map[string]f64
		bpm_changes []RawObject
		tap_notes []object.NoteObject
		directional_notes []object.NoteObject
		stream map[string]object.NoteObject

		bars timing.Bars
		timings timing.Timing
}

// Resolver
pub fn (mut beatmap Beatmap) resolve_object_time() {
	for mut note in beatmap.tap_notes {
		time := beatmap.to_time(note.tick)
		note.time.start = time
		note.time.end = time
	}
}

pub fn (mut beatmap Beatmap) resolve_note_sprite() {

}

// Time converters
pub fn (mut beatmap Beatmap) to_tick(measure f64, p f64, q f64) f64 {
	return beatmap.bars.to_tick(measure, p, q)
}

pub fn (mut beatmap Beatmap) to_time(tick f64) f64 {
	return beatmap.timings.to_time(tick)
}