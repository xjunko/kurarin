module gameplay

import math

import framework.audio as f_audio
import game.audio as g_audio

import framework.math.easing
import framework.math.glider
import framework.math.vector
import framework.graphic.sprite

pub struct ComboCounter {
	pub mut:
		combo int
		combo_display int
		combo_font &sprite.NumberSprite = voidptr(0)

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
	scale := math.max<f64>(counter.combo_glider.value, 1.0)
	counter.combo_font.draw_number(counter.combo.str(), vector.Vector2{0, 720 - counter.combo_font.size.y * scale}, vector.top_left, sprite.CommonSpriteArgument{...arg, scale: scale})
}

pub fn make_combo_counter() &ComboCounter {
	mut counter := &ComboCounter{
		combo_break: g_audio.get_sample("combobreak"),
		combo_font: sprite.make_number_font("combo")
	}
	counter.combo_glider.easing = easing.quad_out

	return counter
}