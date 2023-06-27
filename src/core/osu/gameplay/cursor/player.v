module cursor

import framework.graphic.context
import core.osu.system.player

pub struct PlayerCursor {
pub mut:
	cursor &Cursor
	player player.Player
}

pub fn (mut player_c PlayerCursor) update(time_ms f64, time_delta f64) {
	player_c.cursor.update(time_ms, time_delta)
}

// Creates player cursor
pub fn PlayerCursor.new(mut ctx context.Context) &PlayerCursor {
	mut player_c := &PlayerCursor{
		cursor: Cursor.new(mut ctx)
		player: player.Player{
			name: 'Player'
		}
	}

	player_c.cursor.manual = true

	return player_c
}
