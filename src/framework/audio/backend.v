module audio

import framework.logging
import framework.audio.common
import framework.audio.dummy
import framework.audio.bass

enum BackendType as u8 {
	dummy
	bass
}

__global (
	audio_backend = &common.IBackend(&dummy.DummyMixer{})
	audio_type    = BackendType.bass
)

pub fn init() {
	match audio_type {
		.dummy {}
		.bass {
			audio_backend = &common.IBackend(&bass.BassMixer{})
			audio_backend.init()
		}
	}

	logging.info('Audio Backend: ${audio_type}')
}

// internal apis
pub fn get_required_buffer_size_for_mixer(seconds f64) int {
	return audio_backend.get_required_buffer_size_for_mixer(seconds)
}

pub fn get_mixer_data(mut buffer []u8) {
	audio_backend.get_mixer_data(mut buffer)
}

// public music api
pub fn new_track(path string) &common.ITrack {
	return audio_backend.new_track(path)
}

pub fn new_sample(path string) &common.ISample {
	return audio_backend.new_sample(path)
}

// dummy apis
pub fn new_dummy_track() &common.ITrack {
	return &common.ITrack(dummy.DummyTrack{})
}

pub fn new_dummy_sample() &common.ISample {
	return &common.ISample(dummy.DummySample{})
}
