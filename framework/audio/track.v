module audio


// Fact
pub fn new_track(path string) &Track {
	mut track := &Track{}
	track.channel = C.BASS_StreamCreateFile(0, path.str, 0, 0, C.BASS_ASYNCFILE | C.BASS_STREAM_AUTOFREE)
	return track
}


// Decl
pub struct Track {
	pub mut:
		channel C.HSTREAM
		pitch   f64
		speed   f64
		fft     []f32 = []f32{len: 512}
}

pub fn (mut track Track) play() {
	C.BASS_ChannelPlay(track.channel, 1)
}

pub fn (mut track Track) set_volume(vol f32) {
	C.BASS_ChannelSetAttribute(track.channel, C.BASS_ATTRIB_VOL, vol)
}

pub fn (mut track Track) set_speed(speed f64) {
	if track.speed != speed {
		track.speed = speed
	}

	C.BASS_ChannelSetAttribute(track.channel, C.BASS_ATTRIB_FREQ, 44100 * speed)
}

pub fn (mut track Track) update(time f64) {
	// Get FFT data
	C.BASS_ChannelGetData(track.channel, &track.fft[0], C.BASS_DATA_FFT1024)
}