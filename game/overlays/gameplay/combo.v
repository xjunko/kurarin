module gameplay

import gx
import math

import framework.audio as f_audio
import game.audio as g_audio

import framework.math.easing
import framework.math.glider
import framework.graphic.sprite

pub struct ComboCounter {
	pub mut:
		combo int
		combo_display int

		combo_break f_audio.Sample

		combo_glider &glider.Glider = glider.new_glider(1.0)
		last_time f64
}

pub fn (mut counter ComboCounter) increase() {
	counter.combo++
	counter.combo_glider.add_event_start(counter.last_time, counter.last_time + 100.0, 1.0, 1.5)
	counter.combo_glider.add_event_start(counter.last_time + 100.0, counter.last_time + 150.0, 1.5, 1.0)
}

pub fn (mut counter ComboCounter) reset() {
	if counter.combo > 20 {
		counter.combo_break.play()
	}

	counter.combo = 0
}

pub fn (mut counter ComboCounter) update(time f64) {
	counter.combo_glider.update(time)
	counter.last_time = time
}

pub fn (mut counter ComboCounter) draw(arg sprite.CommonSpriteArgument) {
	arg.ctx.draw_text(0, int(720.0 - 16.0 - (32.0 * math.max<f64>(counter.combo_glider.value, 1.0))), "x${counter.combo}", gx.TextCfg{color: gx.white, size: int(16.0 + (32.0 * math.max<f64>(counter.combo_glider.value, 1.0)))})
}

pub fn make_combo_counter() &ComboCounter {
	mut counter := &ComboCounter{
		combo_break: g_audio.get_sample("combobreak")
	}
	counter.combo_glider.easing = easing.quad_out

	return counter
}