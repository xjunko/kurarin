module cursor

import core.osu.system.player

pub interface ICursorController {
mut:
	cursor &Cursor
	player player.Player
	update(f64)
}
