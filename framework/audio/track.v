module audio


// Fact
pub fn new_track(path string) &Track {
	mut track := &Track{}

	// Load?
	track.channel = C.BASS_StreamCreateFile(0, path.str, 0, 0, C.BASS_STREAM_DECODE | C.BASS_STREAM_PRESCAN | C.BASS_ASYNCFILE)

	// FX?
	track.channel = C.BASS_FX_TempoCreate(track.channel, C.BASS_FX_FREESOURCE|C.BASS_STREAM_DECODE)
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
	pub mut:
		channel C.HSTREAM
		pitch   f64
		speed   f64
		fft     []f32 = []f32{len: 512}
		boost   f32
		playing bool
}

pub fn (mut track Track) play() {
	// C.BASS_ChannelPlay(track.channel, 1)
	C.BASS_Mixer_StreamAddChannel(global.master, track.channel, C.BASS_MIXER_CHAN_NORAMPIN|C.BASS_MIXER_CHAN_BUFFER)
	track.playing = true
}

pub fn (mut track Track) set_volume(vol f32) {
	C.BASS_ChannelSetAttribute(track.channel, C.BASS_ATTRIB_VOL, vol)
}

pub fn (mut track Track) set_speed(speed f64) {
	if track.speed != speed {
		track.speed = speed
	}

	C.BASS_ChannelSetAttribute(track.channel, C.BASS_ATTRIB_TEMPO, (speed-1.0)*100)
}

pub fn (mut track Track) set_pitch(pitch f64) {
	if track.pitch != pitch{
		track.pitch = pitch
	}

	C.BASS_ChannelSetAttribute(track.channel, C.BASS_ATTRIB_TEMPO_PITCH, (pitch-1.0)*14.4)
}

pub fn (mut track Track) update(time f64) {
	// Get FFT data
	// C.BASS_ChannelGetData(track.channel, &track.fft[0], C.BASS_DATA_FFT1024)

	// // calculate peak
	// mut boost := f32(0.0)
	// for i := 0; i < 10; i++ {
	// 	boost += (track.fft[i] * track.fft[i]) * (10.0 - f32(i)) / 10.0
	// }

	// track.boost = boost
}