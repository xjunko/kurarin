module cursor

import os

import library.gg
import library.lzma

import framework.math.time

import core.osu.beatmap.object

const (
	osu_M1 = 1 << 0
	osu_M2 = 1 << 1
	osu_K1 = 1 << 2
	osu_K2 = 1 << 3
)

pub struct ReplayEvent {
	pub:
		time f64
		keys int
}

pub struct ReplayCursor {
	pub mut:
		cursor &Cursor

		keys [4]bool
		events []ReplayEvent
}

pub fn (mut replay ReplayCursor) update(time f64) {
	for i := 0; i < replay.events.len; i++ {
		if time >= replay.events[i].time {
			keys := replay.events[i].keys

			replay.cursor.left_button = ((keys & osu_M1) == osu_M1) || ((keys & osu_K1) == osu_K1)
			replay.cursor.right_button = ((keys & osu_M2) == osu_M2) ||  ((keys & osu_K2) == osu_K2)

			replay.events = replay.events[1..]
		}
	}
}

pub fn make_replay_cursor(mut ctx &gg.Context, path_to_replay string) &ReplayCursor {
	mut auto := &ReplayCursor{
		cursor: make_cursor(mut ctx)
	}

	auto.cursor.position.x = 512.0 / 2.0
	auto.cursor.position.y = 384.0 / 2.0

	// Read crap
	raw_lzma := os.read_bytes(path_to_replay) or { panic("[Parser] Replay not found!") }
	actions := lzma.decode_lzma(raw_lzma).split(",").filter(it.trim_space().len != 0)

	mut replay_time := 0.0
	mut last_pos := [0.0, 0.0]

	for action in actions {
		items := action.split("|")

		if items.len != 4 {
			panic("[Parser] Replay is fucked up")
		}

		delta := items[0].f64()
		replay_time += delta

		// Movement
		current_x := items[1].f64()
		current_y := items[2].f64()
		
		auto.cursor.add_transform(typ: .move, time: time.Time{replay_time - delta, replay_time}, before: [last_pos[0], last_pos[1]], after: [current_x, current_y])

		last_pos[0] = current_x
		last_pos[1] = current_y

		// Keys
		keys := items[3].int()
		auto.events << ReplayEvent{
			time: replay_time,
			keys: keys
		}

		last_keys = keys
	}

	// Filter out retarded keys event
	auto.events = auto.events.filter(it.time >= 0.0)

	return auto
}