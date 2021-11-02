module audio


import time
import rand
import lib.miniaudio

import framework.math.time as time2

pub const (
	global = &AudioController{master: 0}
)

pub struct AudioController {
	pub mut:
		master &miniaudio.Device = voidptr(0)
		sounds []&miniaudio.Sound
}

pub struct AddAudioArgument {
	mut:
		path string
		time &time2.TimeCounter = 0
		volume f32 = 0.1
		speed  f64 = 1.0

}

pub fn (mut audio AudioController) add_audio(arg AddAudioArgument) &miniaudio.Sound {
	mut sound := miniaudio.sound(filename: arg.path, speed: arg.speed)
	sound.volume(arg.volume)

	// add into sounds list
	audio.sounds << sound

	// add into miniaudio master
	audio.master.add('${audio.sounds.len}::${rand.int()}', sound)

	return sound
}

pub fn (mut audio AudioController) add_audio_and_play(arg_ AddAudioArgument) {
	mut sound := audio.add_audio(arg_)
	mut arg := arg_
	
	go fn (mut sound &miniaudio.Sound) {
		sound.play()

		time.sleep(sound.length() * time.millisecond)
	}(mut sound)

	if !isnil(arg.time) {
		arg.time.reset()
	}
}

pub fn (mut audio AudioController) add_audio_and_play_blocking(arg_ AddAudioArgument) {
	mut sound := audio.add_audio(arg_)
	mut arg := arg_
	
	sound.play()

	if !isnil(arg.time) {
		arg.time.reset()
	}
}

pub fn get_audio_controller() &AudioController {
	mut audio := &AudioController{
		master: miniaudio.device()
	}

	return audio
}

fn init() {
	mut audio_ptr := global
	audio_ptr.master = miniaudio.device()
	println('> Global AudioController Initialized!')
}