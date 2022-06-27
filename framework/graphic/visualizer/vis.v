module visualizer

import framework.audio
import library.gg
import gx

import framework.math.vector

pub struct Visualizer {
	pub mut:
		jump_size int = 10
		jump_counter int
		bars int = 200
		update_delay f64 = 50.0
		decay_value f64 = 0.0024
		bar_length f64 = 400
		start_distance f64 = 1.0
		last_time f64
		counter f64
		fft []f64 = []f64{len: 200}
		music &audio.Track

		// logo stuff
		logo_position vector.Vector2
		logo_size     vector.Vector2
}

pub fn (mut vis Visualizer) update_logo(position vector.Vector2, size vector.Vector2) {
	vis.logo_position = position
	vis.logo_size = size
}

pub fn (mut vis Visualizer) update(time f64) {
	delta := time - vis.last_time

	vis.counter += delta
	mut decay := delta * vis.decay_value

	mult := 0.5 // Change this to increase the "oopmh"

	if vis.counter >= vis.update_delay {
		fft := &vis.music.fft

		for i := 0; i < vis.bars; i++ {
			value := unsafe { fft[(i + vis.jump_counter) % vis.bars] * mult }

			if value > vis.fft[i] {
				vis.fft[i] = value
			}
		}

		vis.jump_counter = (vis.jump_counter + vis.jump_size) % vis.bars
		vis.counter -= vis.update_delay
	}

	for i := 0; i < vis.bars; i++ {
		vis.fft[i] -= (vis.fft[i] + 0.03) * decay
		if vis.fft[i] < 0 {
			vis.fft[i] = 0
		}
	}

	vis.last_time = time
}

pub fn (mut vis Visualizer) draw(mut ctx &gg.Context) {
	cutoff := 1.0 / vis.bar_length

	position := vis.logo_position
	size := vis.logo_size

	// Top
	for i := 0; i < 4; i++ {
		for j, v in vis.fft {
			if v < cutoff {
				continue
			}
			
			// const
			mut thickness := f32(1)
			
			// Default for Top
			mut x := f32(position.x) + f32((f64(j) / vis.bars) * size.x)
			mut y := f32(position.y)
			mut width := thickness
			mut height := -f32(v * size.y)

			
			if i == 1 { // Right
				x = f32(position.x + size.x)
				y = f32(position.y) + f32((f64(j) / vis.bars) * size.y)
				height = thickness
				width = f32(v * size.x)

			} else if i == 2 { // Down
				y += f32(size.y)
				height *= -1

			} else if i == 3 { // Left
				x = f32(position.x)
				y = f32(position.y) + f32((f64(j) / vis.bars) * size.y)
				height = thickness
				width = -f32(v * size.x)
			}

			ctx.draw_rect_filled(x, y, width, height, gx.white)
		}
	}

	// Shadow
	for i := 0; i < 4; i++ {
		for j, v in vis.fft {
			if v < cutoff {
				continue
			}
			
			// const
			mut thickness := f32(2)
			
			// Default for Top
			mut x := f32(position.x) + f32((f64(j) / vis.bars) * size.x)
			mut y := f32(position.y)
			mut width := thickness
			mut height := -f32(v * size.y)

			
			if i == 1 { // Right
				x = f32(position.x + size.x)
				y = f32(position.y) + f32((f64(j) / vis.bars) * size.y)
				height = thickness
				width = f32(v * size.x)

			} else if i == 2 { // Down
				y += f32(size.y)
				height *= -1

			} else if i == 3 { // Left
				x = f32(position.x)
				y = f32(position.y) + f32((f64(j) / vis.bars) * size.y)
				height = thickness
				width = -f32(v * size.x)
			}

			ctx.draw_rect_filled_add(x, y, width, height, gx.purple)
		}
	}

	
}