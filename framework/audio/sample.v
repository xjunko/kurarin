module audio

pub fn new_sample(path string) &Sample {
	mut sample := &Sample{}
	sample_id := C.BASS_SampleLoad(0, path.str, 0, 0, 10, 0)
	sample.channel = C.BASS_SampleGetChannel(sample_id, 0)
	return sample
}

pub struct Sample {
	Track
}
