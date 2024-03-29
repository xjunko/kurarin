module bass

import core.common.settings
import framework.audio.common

pub fn (mut bass_mixer BassMixer) new_sample(path string) &common.ISample {
	mut sample := &Sample{
		mixer: unsafe { bass_mixer }
		effects: &common.AudioEffects{}
	}
	sample.bass_sample = C.BASS_SampleLoad(0, path.str, 0, 0, 32, C.BASS_SAMPLE_OVER_POS)

	return &common.ISample(sample)
}

pub struct SampleChannel {
pub mut:
	source  C.HSAMPLE
	channel C.HSTREAM
}

pub struct Sample {
	Track
pub mut:
	bass_sample C.HSAMPLE
}

pub fn (mut sample Sample) play_volume(vol f32) {
	mut channel := &SampleChannel{
		source: sample.bass_sample
	}
	channel.channel = C.BASS_SampleGetChannel(channel.source, C.BASS_SAMCHAN_STREAM | C.BASS_STREAM_DECODE)

	C.BASS_ChannelSetAttribute(channel.channel, C.BASS_ATTRIB_VOL, f32((settings.global.audio.sample / 100.0) * (settings.global.audio.global / 100.0)) * vol)
	C.BASS_Mixer_StreamAddChannel(sample.mixer.master, channel.channel, C.BASS_MIXER_CHAN_NORAMPIN | C.BASS_STREAM_AUTOFREE)
}

pub fn (mut sample Sample) play() {
	sample.play_volume(1.0) // Default sample volume
}
