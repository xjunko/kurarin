module graphic

// import gx
import sokol.sgl

import framework.graphic.sprite
import framework.math.vector
import framework.math.time
import framework.transform

pub struct SliderRenderer {
	pub mut:
		time   &time.Time = voidptr(0)
		points []vector.Vector2
		fade   transform.Transform

		// time
		render_time f64
}

pub fn (mut slider SliderRenderer) process() {

}

pub fn (mut slider SliderRenderer) update(time f64) {
	slider.render_time = time
}

pub fn (mut slider SliderRenderer) draw(arg sprite.DrawConfig) {
	/*
	if slider.render_time >= slider.time.start && slider.render_time <= slider.time.end {
		sgl.c4b(255, 0, 0, 255)
		sgl.begin_line_strip()

		for point in slider.points {
			sgl.v2f(f32(point.x), f32(point.y))
		}

		sgl.end()
	}
	*/
}

pub fn (mut slider SliderRenderer) draw_and_update(arg sprite.DrawConfig) {
	slider.update(0)
	slider.draw(arg)
}