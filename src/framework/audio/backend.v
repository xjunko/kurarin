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
		panic('Dummy audio backend: Unimplemented.')
	}
}

pub fn new_track(path string) &common.ITrack {
	return unsafe { audio.boxed_backend.backend.new_track(path) }
}

pub fn new_sample(path string) &common.ISample {
	return unsafe { audio.boxed_backend.backend.new_sample(path) }
}

pub fn new_dummy_track() &common.ITrack {
	return &common.ITrack(dummy.DummyTrack{
		effects: &common.AudioEffects{}
	})
}

pub fn new_dummy_sample() &common.ISample {
	return &common.ISample(dummy.DummySample{
		effects: &common.AudioEffects{}
	})
}

// Type alias
pub type IBackend = common.IBackend
pub type ITrack = common.ITrack
pub type ISample = common.ISample

pub type DummyTrack = dummy.DummyTrack
pub type DummySample = dummy.DummySample
