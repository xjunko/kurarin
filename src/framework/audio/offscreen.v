module audio

pub fn get_required_buffer_size_for_mixer(seconds f64) int {
	return int(C.BASS_ChannelSeconds2Bytes(global.master, seconds))
}

pub fn get_mixer_data(mut buffer []u8) {
	C.BASS_ChannelGetData(global.master, buffer.data, buffer.len)
}
