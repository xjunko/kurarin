module gameplay

import gg
import core.osu.system.skin
import core.osu.system.player
import framework.math.vector
import framework.graphic.sprite

pub struct ScoreBoard {
pub mut:
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
	arg.ctx.draw_text(10, 313 + 10, scoreboard.player.player_name,
		color: gg.Color{255, 255, 255, 255}
		size: int(18 * arg.scale)
	)

	scoreboard.counter.main_font.draw_number(scoreboard.counter.combo.str(), vector.Vector2[f64]{133 * arg.scale,
		313 + f32(50 * arg.scale)}, vector.bottom_right, sprite.CommonSpriteArgument{
		...arg
		scale: 0.4 * arg.scale
	})
}

pub fn make_score_board(counter &ComboCounter, player_info player.Player) &ScoreBoard {
	mut scoreboard := &ScoreBoard{
		counter: unsafe { counter }
		player: player_info
		background: skin.get_texture('menu-button-background')
	}

	return scoreboard
}
