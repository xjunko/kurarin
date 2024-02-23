module bass

pub fn (mut bass_mixer BassMixer) get_required_buffer_size_for_mixer(seconds f64) int {
	return int(C.BASS_ChannelSeconds2Bytes(bass_mixer.master, seconds))
}

pub fn (mut bass_mixer BassMixer) get_mixer_data(mut buffer []u8) {
	C.BASS_ChannelGetData(bass_mixer.master, buffer.data, buffer.len)
}
