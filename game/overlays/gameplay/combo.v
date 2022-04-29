module gameplay

import framework.audio as f_audio
import game.audio as g_audio

pub struct ComboCounter {
	pub mut:
		combo int
		combo_display int

		combo_break f_audio.Sample
}

pub fn (mut counter ComboCounter) increase() {
	counter.combo++
}

pub fn (mut counter ComboCounter) reset() {
	if counter.combo > 20 {
		counter.combo_break.play()
	}

	counter.combo = 0
}

pub fn make_combo_counter() &ComboCounter {
	mut counter := &ComboCounter{
		combo_break: g_audio.get_sample("combobreak")
	}

	return counter
}