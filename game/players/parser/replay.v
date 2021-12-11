module parser

import os
import framework.math.vector { Vector2 }
import framework.math.time as time2

import game.players.structs { ReplayEvent, ReplayKeys }

enum GameMode {
	std
	taiko
	ctb
	mania
}

struct Accurancy {
pub mut:
	n300  int
	n100  int
	n50   int
	ngeki int
	nkatu int
	nmiss int
}

struct Replay {
pub mut:
	buffer      &Buffer
	mode        GameMode
	version     int
	bmap_hash   string
	player      string
	replay_hash string
	acc         Accurancy
	score       int
	max_combo   int
	perfect     bool
	mods        int
	lifebar     string
	time        int
	events      []ReplayEvent
}

pub fn (mut replay Replay) parse_event() {
	lzma_len := replay.buffer.read_int()
	lzma_raw := replay.buffer.read_bytes(lzma_len)

	// TODO: use c library lmao
	println('> Using python to decompress LZMA shit')
	raw_data := decode_raw(lzma_raw).map(fn (it byte) string { return it.ascii_str() }).join("")

	events_data := raw_data.split(',')

	mut time := 0
	for evt_data in events_data {
		event := evt_data.split('|')

		if event.len != 4 {
			continue
		}
		position := Vector2{
			x: event[1].f32()
			y: event[2].f32()
		}

		replay.events << ReplayEvent{
			position: position
			time: time2.Time{start: time, end: time + event[0].f64()}
			keys: ReplayKeys{k1: (event[3].int() & 1 == 1), k2: (event[3].int() & 4 == 4)}
		}

		time += event[0].int()
	}
}

pub fn (mut replay Replay) find_closest(time f32) ReplayEvent {
	mut closest := ReplayEvent{}

	for event in replay.events {
		if time >= event.time.start {
			closest = event
		}
	}

	return closest
}

pub fn parse_replay(path string) ?Replay {
	raw := os.read_file(path) ?
	mut buf := Buffer{
		view: raw.bytes()
	}

	mut replay := Replay{
		buffer: &buf
	}

	// lets go
	replay.mode = GameMode(buf.read_byte())
	replay.version = buf.read_int()
	replay.bmap_hash = buf.read_string()
	replay.player = buf.read_string()
	replay.replay_hash = buf.read_string()
	replay.acc.n300 = buf.read_short()
	replay.acc.n100 = buf.read_short()
	replay.acc.n50 = buf.read_short()
	replay.acc.ngeki = buf.read_short()
	replay.acc.nkatu = buf.read_short()
	replay.acc.nmiss = buf.read_short()
	replay.score = buf.read_int()
	replay.max_combo = buf.read_short()
	replay.perfect = buf.read_byte() == 0x00
	replay.mods = buf.read_int()
	replay.lifebar = buf.read_string()
	replay.time = buf.read_long()
	replay.parse_event()

	return replay
}
