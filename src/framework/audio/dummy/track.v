module dummy

import framework.audio.common

// Structs
pub struct DummyTrack {
pub mut:
	path    string
	playing bool

	effects &common.AudioEffects
}

pub fn (mut dummy_track DummyTrack) play() {}

pub fn (mut dummy_track DummyTrack) pause() {}

pub fn (mut dummy_track DummyTrack) resume() {}

pub fn (mut dummy_track DummyTrack) set_volume(vol f32) {}

pub fn (mut dummy_track DummyTrack) set_position(millis f64) {}

pub fn (mut dummy_track DummyTrack) set_speed(new_speed f64) {}

pub fn (mut dummy_track DummyTrack) set_pitch(new_pitch f64) {}

pub fn (mut dummy_track DummyTrack) update(update_time f64) {}

pub fn (mut dummy_track DummyTrack) get_position() f64 {
	return 0.0
}
