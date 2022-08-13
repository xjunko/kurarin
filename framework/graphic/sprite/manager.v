module sprite

import time as timelib
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
	sprite.id = manager.queue.len
}

// TODO: This is slow cuz `O(n)`, but only used once per end time so idk
pub fn (mut manager Manager) find_index_by_id(id int) int {
	for i, s in manager.queue {
		if s.id == id { return i }
	}

	return -1
}

pub fn (mut manager Manager) update(time f64) {
	manager.last_time = time

	for mut sprite in manager.queue {
		// Remove
		if time >= sprite.time.end && !sprite.always_visible {
			// start := f64(timelib.ticks())
			$if project_sekai ? {
				manager.queue.delete(manager.find_index_by_id(sprite.id))
			} $else {
				manager.queue.delete(manager.queue.index(sprite))
			}
			
			// println("Took: ${f64(timelib.ticks()) - start:.10} to finish")
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