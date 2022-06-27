module sprite

import framework.math.camera

pub struct Manager {
	pub mut:
		queue []&Sprite
		camera camera.Camera
		dirty bool

		last_time f64
}

pub fn (mut manager Manager) add(mut sprite Sprite) {
	manager.queue << unsafe { &sprite }
}

pub fn (mut manager Manager) update(time f64) {
	manager.last_time = time

	for mut sprite in manager.queue {
		// Remove
		if time >= sprite.time.end && !sprite.always_visible {
			manager.queue.delete(manager.queue.index(sprite))
			continue
		}

		if sprite.is_drawable_at(time) || sprite.always_visible {
			sprite.update(time)
		}
	}
}

pub fn (mut manager Manager) draw(arg CommonSpriteArgument) {
	for mut sprite in manager.queue {
		sprite.draw(arg)
	}
}

pub fn (mut manager Manager) draw_internal_camera(arg CommonSpriteArgument) {
	manager.draw(CommonSpriteArgument{...arg, camera: manager.camera})
}


// Make
pub fn make_manager() &Manager {
	mut manager := &Manager{}
	return manager
}