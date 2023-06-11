module gui

import framework.graphic.sprite

pub struct CustomSpriteManager {
	sprite.Manager
}

pub fn (mut sprite_manager CustomSpriteManager) fadeout_and_die(time_to_die f64, time_took_to_die f64) {
	for i, _ in sprite_manager.queue {
		sprite_manager.queue[i].time.end = time_to_die + time_took_to_die
		sprite_manager.queue[i].always_visible = false
	}
}
