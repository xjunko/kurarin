module audio

import time
import library.miniaudio

//
import framework.logging

pub const (
	global = &AudioAttr{}
)

// HACK: Globals
struct AudioAttr {
	pub mut:
		main  	  &miniaudio.AudioDevice = voidptr(0)
}

// Play FNs
fn internal_play(arg miniaudio.AddAudioArg, mut device &miniaudio.AudioDevice) {
	mut audio := device.add_audio(arg)

	go fn (mut audio &miniaudio.Audio) {
		audio.play()
		time.sleep(audio.length() * time.millisecond)
		audio.free()
	}(mut audio)
}

pub fn play(arg miniaudio.AddAudioArg) {
	mut device := get_main_device()
	internal_play(arg, mut device)
}

// 
pub fn get_main_device() &miniaudio.AudioDevice {
	return global.main
}

// Init
fn init() {
	mut global_ptr := global
	global_ptr.main = miniaudio.make_device()
	logging.info("AudioDevice initialized!")
}
