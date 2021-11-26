module canvas

import lib.gg
import gx

import framework.math.vector
import framework.graphic.sprite

import game.beatmap.object
import game.math.difficulty

pub struct Canvas {
	pub mut:
		size              &vector.Vector2 = &vector.Vector2{512, 384}
		scale             f64 = 1
		position   		  &vector.Vector2 = &vector.Vector2{0, 0}
		drawables  		  []sprite.IDrawable
		special_drawables []sprite.IDrawable
		hitobjects        []object.IHitObject
}

pub fn (mut c Canvas) add_drawable(mut s sprite.IDrawable) {
	if s.special {
		c.special_drawables << s
		return
	}
	c.drawables << s
}

pub fn (mut c Canvas) add_hitobject(mut o object.IHitObject) {
	c.hitobjects << o

	// SLIDERRRR
	for mut sprite in o.sprites {
		if sprite.special {
			c.add_drawable(mut sprite)
		}
	}
}

pub fn (mut c Canvas) update(time f64) {
	// remove shit
	// c.sprites = c.sprites.filter(it.time.end > time)
	// c.hitobjects = c.hitobjects.filter(it.time.end > time)

	// Optimization
	mut hitobjects_to_be_removed := 0
	for mut object in c.hitobjects {

		if time > object.time.end + difficulty.hit_fade_out * 2 { // 4/2/1
			hitobjects_to_be_removed++
			continue
		}

		for mut sprite in object.sprites {
			sprite.update(time)
		}
	}
	c.hitobjects = c.hitobjects[hitobjects_to_be_removed ..]

	for mut drawable in c.drawables {
		drawable.update(time)
	}
}

pub fn (mut c Canvas) draw(ctx &gg.Context, time f64) {
	// Render this backwards cuz yes
	for i := c.hitobjects.len - 1; i >= 0; i-- {
		if i >= c.hitobjects.len || i < 0 { println("> ${@FN}: fucked index: i=${i} - max=${c.hitobjects.len}") break}

		mut hitobject := &c.hitobjects[i]
		for mut sprite in hitobject.sprites {
			if sprite.special { continue }
			sprite.draw(ctx: ctx, time: time, offset: c.position, scale: c.scale, size: c.size)
		}
	}
	
	for mut drawable in c.drawables {
		drawable.draw(ctx: ctx, time: time, offset: c.position, scale: c.scale, size: c.size)
	}
}

pub fn (mut c Canvas) draw_and_update(ctx &gg.Context, time f64) {
	c.update(time)
	c.draw(ctx, time)
}

pub fn (c Canvas) draw_canvas_debug(ctx &gg.Context) {
	ctx.draw_rect(
		f32(c.position.x * c.scale), 
		f32(c.position.y * c.scale), 
		f32(c.size.x * c.scale), 
		f32(c.size.y * c.scale), 
		gx.Color{0, 255, 0, 100}
	)
}

pub fn (c Canvas) draw_into(ctx &gg.Context, mut s sprite.Sprite, time f64) {
	s.draw_and_update(ctx: ctx, time: time, offset: c.position, scale: c.scale, size: c.size)
}