module dummy

import framework.audio.common

pub struct DummyMixer {
}

// Internal
pub fn (mut dummy_mixer DummyMixer) init() {}

pub fn (mut dummy_mixer DummyMixer) get_required_buffer_size_for_mixer(seconds f64) int {
	return 0
}

pub fn (mut dummy_mixer DummyMixer) get_mixer_data(mut buffer []u8) {
}

// Audio creation
pub fn (mut dummy_mixer DummyMixer) new_track(path string) &common.ITrack {
	return &DummyTrack{
		path: path
		effects: &common.AudioEffects{}
	}
}

pub fn (mut dummy_mixer DummyMixer) new_sample(path string) &common.ISample {
	return &DummySample{
		path: path
		effects: &common.AudioEffects{}
	}
}

// Dummy audio backend - might no need this.
fn init() {}
