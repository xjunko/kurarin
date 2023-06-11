module replay

import os
import library.elzma as lzma
import core.osu.system.player

pub struct ReplayFrame {
pub mut:
	time     f64
	delta    f64
	position [2]f64
	keys     int
}

pub struct Replay {
mut:
	data   []u8
	offset int
pub mut:
	mode        int
	osu_version int

	map_md5    string
	replay_md5 string

	n300  int
	n100  int
	n50   int
	ngeki int
	nkatu int
	nmiss int

	score     int
	max_combo int
	perfect   int
	mods      int

	life_graph string
	timestamp  i64

	frames []ReplayFrame
	player player.Player
}

pub fn (mut replay Replay) load(path string) {
	replay.data = os.read_bytes(path) or {
		panic('Failed to load replay file for path: ${path} | Reason: ${err}')
	}
	replay.offset = 0
	replay.parse()

	println(replay.player)
}

// High level reading
pub fn (mut replay Replay) parse() {
	replay.parse_headers()
	replay.parse_frames()
}

pub fn (mut replay Replay) parse_headers() {
	replay.mode = replay.read_byte()
	replay.osu_version = replay.read_int()
	replay.map_md5 = replay.read_string()
	replay.player.name = replay.read_string()
	replay.replay_md5 = replay.read_string()
	replay.n300 = replay.read_short()
	replay.n100 = replay.read_short()
	replay.n50 = replay.read_short()
	replay.ngeki = replay.read_short()
	replay.nkatu = replay.read_short()
	replay.nmiss = replay.read_short()
	replay.score = replay.read_int()
	replay.max_combo = replay.read_short()
	replay.perfect = replay.read_byte()
	replay.mods = replay.read_int()

	replay.life_graph = replay.read_string()
	replay.timestamp = replay.read_long()
}

pub fn (mut replay Replay) parse_frames() {
	lzma_length := replay.read_int()

	if lzma_length > 0 {
		lzma_data := replay.read_raw(lzma_length)
		replay.read_frames(lzma_data)
	}
}

pub fn (mut replay Replay) read_frames(data []u8) {
	if lzma_data := lzma.decode_lzma(data) {
		actions := lzma_data.split(',').filter(it.len > 0)

		skip_offs_str := actions[1].split_nth('|', 2)[0]
		mut skip_offset := 0

		if skip_offs_str != '-1' {
			skip_offset = skip_offs_str.int()
		}

		mut prev_keys := 0
		mut total_delta := skip_offset

		for action in actions#[2..-1] {
			items := action.split('|')

			if items.len != 4 {
				return
			}

			delta := items[0].int()
			total_delta += delta

			keys := items[3].int()

			replay.frames << ReplayFrame{
				delta: delta
				time: total_delta
				position: [items[1].f64(), items[2].f64()]!
				keys: keys
			}

			prev_keys = keys
		}

		// NOTE: noop to make the thing shup up
		prev_keys += 42069
		prev_keys -= 42069
		prev_keys = prev_keys
	} else {
		panic("[Replay] Failed to decode replay's lzma data!!")
	}
}

// Lower level reading
pub fn (mut replay Replay) read_raw(length int) []u8 {
	val := replay.data[replay.offset..][..length]
	replay.offset += length
	return val
}

pub fn (mut replay Replay) read_byte() u8 {
	return replay.read_raw(1)[0]
}

pub fn (mut replay Replay) read_short() int {
	val := replay.read_raw(2).map(u32(it))

	mut n := (val[1] << 8) | val[0]

	if (n & 0x8000) != 0 {
		n -= 0x10000
	}

	return int(n)
}

pub fn (mut replay Replay) read_int() int {
	val := replay.read_raw(4).map(u32(it))

	return int((val[3] << 24) | (val[2] << 16) | (val[1] << 8) | val[0])
}

pub fn (mut replay Replay) read_long() i64 {
	val := replay.read_raw(8).map(u64(it))
	mut n := u64((val[7] << 56) | (val[6] << 48) | (val[5] << 40) | (val[4] << 32) | (val[3] << 24) | (val[2] << 16) | (val[1] << 8) | val[0])

	// error: integer literal 0x10000000000000000 overflows int
	// if (n & 0x8000000000000000) != 0 {
	// 	n -= 0x10000000000000000
	// }

	return i64(n)
}

pub fn (mut replay Replay) read_uleb128() int {
	mut val := u32(0)
	mut shift := u32(0)

	for {
		b := u32(replay.read_byte())

		val |= ((b & 127) << shift)

		if (b & 128) == 0 {
			break
		}

		shift += 7
	}

	return int(val)
}

pub fn (mut replay Replay) read_string() string {
	if replay.read_byte() == 0 {
		return ''
	}

	uleb := replay.read_uleb128()
	return replay.read_raw(uleb).bytestr()
}

// fn main() {
// 	mut replay := &Replay{}
// 	replay.load('/run/media/junko/2nd/Games/osu!/Replays/arissarazie - cillia - Fairytale, [Torment] (2020-02-28) Osu.osr')

// 	// println(replay)
// }
