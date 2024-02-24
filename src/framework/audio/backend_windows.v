module audio

import framework.audio.common
import framework.audio.dummy

pub const boxed_backend = &Boxed{&common.IBackend(&dummy.DummyMixer{})}

pub struct Boxed {
pub mut:
	backend &common.IBackend
}

pub fn init() {
	println('[DEBUG] Dummy audio initialized.')
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
