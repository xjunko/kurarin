module logic

import lib.gg
import gx

import framework.math.vector
import framework.math.time

import game.math.difficulty

// TODO: proper logic lmao

pub struct HitCircle {
	pub mut:
		position &vector.Vector2 = voidptr(0)
		time     time.Time
		radius   f64 = 50
		range    f64 = 1 // this is stupid
		clicked  bool
		diff     difficulty.Difficulty

		// canvas bullshit
		canvas_offset vector.Vector2
		canvas_scale  f64
		canvas_size   vector.Vector2
		
}

// Circular import bullshit so had to do this
pub fn (mut hitcircle HitCircle) add_canvas(position vector.Vector2, scale f64, size vector.Vector2) {
	unsafe { // unsafe code very unsafe !!!! unsafe !!!! 11111
		hitcircle.canvas_offset = position
		hitcircle.canvas_size = size
	}
	hitcircle.canvas_scale = scale
	
}

pub fn (hitcircle HitCircle) draw_debug_hitbox(ctx &gg.Context, time f64) {
	if hitcircle.is_hittable(time) && !hitcircle.clicked {
		ctx.draw_rect(
            f32(((hitcircle.position.x + hitcircle.canvas_offset.x) - hitcircle.radius / 2) * hitcircle.canvas_scale),
            f32(((hitcircle.position.y + hitcircle.canvas_offset.y) - hitcircle.radius / 2) * hitcircle.canvas_scale),
            f32(hitcircle.radius * hitcircle.canvas_scale),
            f32(hitcircle.radius * hitcircle.canvas_scale),
            gx.Color{255, 0, 0, 50}
        )
	}
}

/*
((x > hitcircle.position.x - hitcircle.radius / 2) && (x < (hitcircle.position.x + hitcircle.radius / 2))) &&
((y > hitcircle.position.y - hitcircle.radius / 2) && (y < (hitcircle.position.y + hitcircle.radius / 2)))
*/
pub fn (hitcircle HitCircle) is_cursor_on_hitcircle(x f64, y f64, using_osu_space bool) bool {
	if using_osu_space {
		return 
			((x > hitcircle.position.x - hitcircle.radius / 2) && (x < (hitcircle.position.x + hitcircle.radius / 2))) &&
			((y > hitcircle.position.y - hitcircle.radius / 2) && (y < (hitcircle.position.y + hitcircle.radius / 2)))
	}
	return 
		((x > ((hitcircle.position.x + hitcircle.canvas_offset.x) - hitcircle.radius / 2) * hitcircle.canvas_scale) && (x < ((hitcircle.position.x + hitcircle.canvas_offset.x) + hitcircle.radius / 2) * hitcircle.canvas_scale)) &&
		((y > ((hitcircle.position.y + hitcircle.canvas_offset.y) - hitcircle.radius / 2) * hitcircle.canvas_scale) && (y < ((hitcircle.position.y + hitcircle.canvas_offset.y) + hitcircle.radius / 2) * hitcircle.canvas_scale))
}

pub fn (hitcircle HitCircle) is_hittable(time f64) bool {
	return 
			(time > (hitcircle.time.start - hitcircle.diff.hit50)) && 
			(time < (hitcircle.time.end + hitcircle.diff.hit50))
}