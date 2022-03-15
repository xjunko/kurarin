module audio

import game.settings

pub fn new_sample(path string) &Sample {
	mut sample := &Sample{}
	sample.bass_sample = C.BASS_SampleLoad(0, path.str, 0, 0, 10, 0)
	return sample
}

pub struct SampleChannel {
	pub mut:
		source C.HSAMPLE
		channel C.HSTREAM
}

pub struct Sample {
	Track

	pub mut:
		bass_sample C.HSAMPLE
}

pub fn (mut sample Sample) play_volume(vol f32) {
	mut channel := &SampleChannel{source: sample.bass_sample}
	channel.channel = C.BASS_SampleGetChannel(channel.source, 0)

	C.BASS_ChannelSetAttribute(channel.channel, C.BASS_ATTRIB_VOL, f32((settings.window.effect_volume / 100.0) * (settings.window.overall_volume / 100.0)) * vol)
	C.BASS_ChannelPlay(channel.channel, 1)
}

pub fn (mut sample Sample) play() {
	sample.play_volume(1.0) // Default sample volume
}
