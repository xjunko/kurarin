module audio


import time
import lib.miniaudio

import framework.math.time as time2

pub const (
	global = &AudioController{master: 0}
)

pub struct AudioController {
	pub mut:
		master &miniaudio.AudioDevice = voidptr(0)
		sounds []&miniaudio.Audio
}

pub struct AddAudioArgument {
	mut:
		path string
		time &time2.TimeCounter = 0
		volume f32 = 0.1
		speed  f64 = 1.0

}

pub fn (mut audio AudioController) add_audio(arg AddAudioArgument) &miniaudio.Audio {
	mut sound := audio.master.add_audio(path: arg.path, speed: arg.speed)
	sound.volume(arg.volume)

	// add into sounds list
	audio.sounds << sound

	// add into miniaudio master
	// audio.master.add('${audio.sounds.len}::${rand.int()}', sound)

	return sound
}

pub fn (mut audio AudioController) add_audio_and_play(arg_ AddAudioArgument) {
	mut sound := audio.add_audio(arg_)
	mut arg := arg_

	sound.play()

	// Free after finished
	go fn (mut audio &miniaudio.Audio) {
		time.sleep(audio.length() * time.millisecond)
		audio.free()
	}(mut sound)
	

	if !isnil(arg.time) {
		arg.time.reset()
	}
}

pub fn (mut audio AudioController) add_audio_and_play_blocking(arg_ AddAudioArgument) {
	audio.add_audio_and_play(arg_)
}

pub fn get_audio_controller() &AudioController {
	mut audio := &AudioController{
		master: miniaudio.make_device()
	}

	return audio
}

pub fn init_audio() {
	mut audio_ptr := global
	audio_ptr.master = miniaudio.make_device()
	println('> Global AudioController Initialized!')
}