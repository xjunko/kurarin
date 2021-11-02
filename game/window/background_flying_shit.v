module window

import rand

import framework.graphic.sprite
import framework.math.time

import game.math.resolution

pub fn generate_bullshit(mut window &GameWindow) {
	if true { // This is more of a testing function to stress test so yea...
		return
	}
	// Generate the flying shit every 10 seconds 
	mut the_cat := window.ctx.create_image('assets/sample2.png')
	end_time := window.beatmap.objects[0].time.end / 1000

	for i := 0; i < end_time; i += 3 {
		for _ in 0 .. rand.int_in_range(10, 50) {
			mut sprite := &sprite.Sprite{
				textures: [the_cat]
			}
			
			target_x := rand.f64_in_range(-the_cat.width, resolution.global.width)
			target_scale := rand.f64_in_range(0.1, 0.5)
			target_time := time.Time{i*1000, i*1000 + rand.int_in_range(900, 9000)}
			sprite.add_transform(typ: .move, time: target_time, before: [target_x, resolution.global.height], after: [f64(target_x), -128.0])
			sprite.add_transform(typ: .scale_factor, time: time.Time{0,0}, before: [target_scale])
			sprite.after_add_transform_reset()

			// add to game canvas
			window.game_canvas.add_sprite(sprite)

			// println(target_time)
		}
	}
}