module dummy

// Structs
pub struct DummySample {
	DummyTrack
}

pub fn (mut dummy_sample DummySample) play() {}

pub fn (mut dummy_sample DummySample) play_volume(volume f32) {}
