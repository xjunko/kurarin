module audio

import framework.logging
import framework.audio.common
import framework.audio.dummy
import framework.audio.bass

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

pub fn new_track(path string) &common.ITrack {
	return audio_backend.new_track(path)
}

pub fn new_sample(path string) &common.ISample {
	return audio_backend.new_sample(path)
}

pub fn new_dummy_track() &common.ITrack {
	return &common.ITrack(dummy.DummyTrack{})
}

pub fn new_dummy_sample() &common.ISample {
	return &common.ISample(dummy.DummySample{})
}
