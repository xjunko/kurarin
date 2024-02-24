module audio

import framework.audio.common
import framework.audio.dummy
import framework.audio.bass

pub const boxed_backend = &Boxed{&common.IBackend(&dummy.DummyMixer{})}
pub const is_bass = true // TODO: Force BASS for now.

pub struct Boxed {
pub mut:
	backend &common.IBackend
}

pub fn init() {
	if audio.is_bass {
		unsafe {
			mut boxed := audio.boxed_backend
			boxed.backend = &common.IBackend(&bass.BassMixer{})
			boxed.backend.init()
		}
	} else {
		println('[DEBUG] Dummy audio initialized.')
	}
}

pub fn new_track(path string) &common.ITrack {
	mut boxed := unsafe { &audio.boxed_backend }
	mut track := boxed.backend.new_track(path)
	return track
}

pub fn new_sample(path string) &common.ISample {
	mut boxed := unsafe { &audio.boxed_backend }
	mut track := boxed.backend.new_sample(path)
	return track
}

pub fn new_dummy_track() &common.ITrack {
	return &common.ITrack(dummy.DummyTrack{})
}

pub fn new_dummy_sample() &common.ISample {
	return &common.ISample(dummy.DummySample{})
}
