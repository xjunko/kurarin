module cursor

import os
import library.gg
import library.lzma
import framework.math.time

const (
	osu_m1 = 1 << 0
	osu_m2 = 1 << 1
	osu_k1 = 1 << 2
	osu_k2 = 1 << 3
)

pub struct ReplayEvent {
pub:
	time f64
	keys int
}

pub struct ReplayCursor {
pub mut:
	cursor &Cursor

	keys   [4]bool
	events []ReplayEvent
}

pub fn (mut replay ReplayCursor) update(update_time f64) {
	for i := 0; i < replay.events.len; i++ {
		if update_time >= replay.events[i].time {
			keys := replay.events[i].keys

			replay.cursor.left_button = ((keys & cursor.osu_m1) == cursor.osu_m1)
				|| ((keys & cursor.osu_k1) == cursor.osu_k1)
			replay.cursor.right_button = ((keys & cursor.osu_m2) == cursor.osu_m2)
				|| ((keys & cursor.osu_k2) == cursor.osu_k2)

			replay.events = replay.events[1..]
		}
	}
}

pub fn make_replay_cursor(mut ctx gg.Context, path_to_replay string) &ReplayCursor {
	mut auto := &ReplayCursor{
		cursor: make_cursor(mut ctx)
	}

	auto.cursor.position.x = 512.0 / 2.0
	auto.cursor.position.y = 384.0 / 2.0

	// Read crap
	raw_lzma := os.read_bytes(path_to_replay) or { panic('[Parser] Replay not found!') }
	actions := lzma.decode_lzma(raw_lzma).split(',').filter(it.trim_space().len != 0)

	mut replay_time := 0.0
	mut last_pos := [0.0, 0.0]

	// Read skip offsets
	skip_offs := actions[1].split_nth('|', 0)[0]
	mut skip_offset := 0.0

	if skip_offs != '-1' {
		skip_offset = skip_offs.f64()
		replay_time = skip_offset
	}

	for action in actions {
		items := action.split('|')

		if items.len != 4 {
			panic('[Parser] Replay is fucked up')
		}

		delta := items[0].f64()
		replay_time += delta

		// Movement
		current_x := items[1].f64()
		current_y := items[2].f64()

		auto.cursor.add_transform(
			typ: .move
			time: time.Time{replay_time - delta, replay_time}
			before: [
				last_pos[0],
				last_pos[1],
			]
			after: [current_x, current_y]
		)

		last_pos[0] = current_x
		last_pos[1] = current_y

		// Keys
		keys := items[3].int()

		auto.events << ReplayEvent{
			time: replay_time
			keys: keys
		}
	}

	// Filter out retarded keys event
	auto.events = auto.events.filter(it.time >= 0.0)

	return auto
}
