module bass

import framework.audio.common

// Struct Based
pub fn (mut bass_mixer BassMixer) new_track(path string) &common.ITrack {
	mut track := &Track{
		mixer: unsafe { bass_mixer }
		effects: &common.AudioEffects{}
	}

	// Load?
	track.channel = C.BASS_StreamCreateFile(0, path.str, 0, 0, C.BASS_STREAM_DECODE | C.BASS_STREAM_PRESCAN | C.BASS_ASYNCFILE)

	// FX?
	track.channel = C.BASS_FX_TempoCreate(track.channel, C.BASS_FX_FREESOURCE | C.BASS_STREAM_DECODE)
	track_setup_fx_channel(track.channel)

	return track
}

pub fn track_setup_fx_channel(channel C.HSTREAM) {
	C.BASS_ChannelSetAttribute(channel, C.BASS_ATTRIB_TEMPO_OPTION_USE_QUICKALGO, 1)
	C.BASS_ChannelSetAttribute(channel, C.BASS_ATTRIB_TEMPO_OPTION_OVERLAP_MS, 4.0)
	C.BASS_ChannelSetAttribute(channel, C.BASS_ATTRIB_TEMPO_OPTION_SEQUENCE_MS, 30.0)
}

// Decl
pub struct Track {
mut:
	mixer &BassMixer
pub mut:
	channel C.HSTREAM
	effects &common.AudioEffects
	pitch   f64
	speed   f64
	playing bool
}

pub fn (mut track Track) play() {
	// C.BASS_ChannelPlay(track.channel, 1)
	C.BASS_Mixer_StreamAddChannel(track.mixer.master, track.channel, C.BASS_MIXER_CHAN_NORAMPIN | C.BASS_MIXER_CHAN_BUFFER)
	track.playing = true
}

pub fn (mut track Track) pause() {
	C.BASS_Mixer_ChannelFlags(track.channel, C.BASS_MIXER_CHAN_PAUSE, C.BASS_MIXER_CHAN_PAUSE)
}

pub fn (mut track Track) resume() {
	C.BASS_Mixer_ChannelFlags(track.channel, 0, C.BASS_MIXER_CHAN_PAUSE)
}

pub fn (mut track Track) set_volume(vol f32) {
	C.BASS_ChannelSetAttribute(track.channel, C.BASS_ATTRIB_VOL, vol)
}

pub fn (mut track Track) set_position(millisecond f64) {
	C.BASS_ChannelSetPosition(track.channel, C.BASS_ChannelSeconds2Bytes(track.channel,
		millisecond / 1000.0), C.BASS_POS_BYTE)
}

pub fn (mut track Track) set_speed(speed f64) {
	if track.speed != speed {
		track.speed = speed
	}

	C.BASS_ChannelSetAttribute(track.channel, C.BASS_ATTRIB_TEMPO, (speed - 1.0) * 100.0)
}

pub fn (mut track Track) set_pitch(pitch f64) {
	if track.pitch != pitch {
		track.pitch = pitch
	}

	C.BASS_ChannelSetAttribute(track.channel, C.BASS_ATTRIB_TEMPO_PITCH, (pitch - 1.0) * 14.4)
}

pub fn (mut track Track) update(time f64) {
	// Get FFT data
	C.BASS_Mixer_ChannelGetData(track.channel, &track.effects.fft_raw[0], C.BASS_DATA_FFT1024)

	// calculate peak
	mut boost := f32(0.0)
	for i := 0; i < 10; i++ {
		boost += (track.effects.fft_raw[i] * track.effects.fft_raw[i]) * (10.0 - f32(i)) / 10.0
	}

	track.effects.peak_raw = boost
	track.effects.peak_smoothed = track.effects.peak_raw * 0.1 + track.effects.peak_smoothed - track.effects.peak_smoothed * 0.1
}

pub fn (mut track Track) get_position() f64 {
	return f64(C.BASS_ChannelBytes2Seconds(track.channel, C.BASS_Mixer_ChannelGetPosition(track.channel,
		C.BASS_POS_BYTE))) * 1000.0
}
