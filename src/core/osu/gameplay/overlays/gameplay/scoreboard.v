module gameplay

import gg
import core.osu.system.skin
import core.osu.system.player
import framework.math.vector
import framework.graphic.sprite

pub interface MainOverlay {
mut:
	score i64
	score_smooth i64
}

pub struct ScoreBoard {
pub mut:
	overlay    MainOverlay
	counter    &ComboCounter
	player     player.Player
	background gg.Image
}

pub fn (mut scoreboard ScoreBoard) update(update_time f64) {
}

pub fn (mut scoreboard ScoreBoard) draw(arg sprite.CommonSpriteArgument) {
	// Background
	arg.ctx.draw_image_with_config(
		img: &scoreboard.background
		img_id: scoreboard.background.id
		img_rect: gg.Rect{
			x: 0
			y: 313
			width: f32(140 * arg.scale)
			height: f32(64 * arg.scale)
		}
		part_rect: gg.Rect{
			x: scoreboard.background.width * 2 / 3
			y: 0
			width: scoreboard.background.width - (scoreboard.background.width * 2 / 3)
			height: scoreboard.background.height
		}
		origin: vector.top_left
		color: gg.Color{80, 80, 80, 255 - u8(255 * 0.3)}
	)

	// Name
	arg.ctx.draw_text(int(4 * arg.scale), int(313 + (12 * arg.scale)), scoreboard.player.name,
		
		color: gg.Color{255, 255, 255, 255}
		size: int(20 * arg.scale)
	)

	// Combo
	arg.ctx.draw_text(int((140 * arg.scale) - (10 * arg.scale)), int(313 + (64 * arg.scale) - (24 * arg.scale)),
		'${humanize_number(scoreboard.counter.max_combo)}x',
		color: gg.Color{153, 237, 255, 255}
		size: int(18 * arg.scale)
		align: .right
	)

	// Score
	arg.ctx.draw_text(int(4 * arg.scale), int(313 + (64 * arg.scale) - (24 * arg.scale)),
		'${humanize_number(scoreboard.overlay.score_smooth)}',
		color: gg.Color{255, 255, 255, 255}
		size: int(18 * arg.scale)
	)
}

pub fn make_score_board(overlay MainOverlay, counter &ComboCounter, player_info player.Player) &ScoreBoard {
	mut scoreboard := &ScoreBoard{
		overlay: overlay
		counter: unsafe { counter }
		player: player_info
		background: skin.get_texture('menu-button-background')
	}

	return scoreboard
}

// Temporary
fn humanize_number[T](number T) string {
	str_n := i64(number).str()

	mut a := str_n.len % 3

	if a == 0 {
		a = 3
	}

	mut humanized := str_n#[0..a]

	for i := a; i < str_n.len; i += 3 {
		humanized += ',' + str_n#[i..i + 3]
	}

	return humanized
}
