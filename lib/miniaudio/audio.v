module miniaudio

pub struct AudioDevice {
	pub mut:
		device &Device
		config C.ma_device_config
		audio  []&Audio

		volume f32
}

pub struct Audio {
	pub mut:
		decoder &Decoder

		playing bool
		volume  f32
}

// Callback loop
fn data_callback(p_device &C.ma_device, p_output voidptr, p_input voidptr, frame_count u32) {
	mut audio_device := &AudioDevice(p_device.pUserData)

	// Play them audio
	for audio in audio_device.audio {
		if !audio.playing {
			continue
		}

		C.ma_decoder_read_pcm_frames(audio.decoder, p_output, frame_count)
	}
}

// AudioDevice FNs
[args]
pub struct AddAudioArg {
	path string
	speed f64 = 1.0
}

pub fn (mut audio_device AudioDevice) add_audio(arg AddAudioArg) &Audio {
	decoder_config := C.ma_decoder_config_init(.f32, 2, 44100 / arg.speed)
	decoder := Decoder{}
	C.ma_decoder_init_file(arg.path.str, &decoder_config, &decoder)

	mut audio := &Audio{decoder: &decoder}

	// Add into device
	audio_device.audio << audio

	return audio
}

pub fn (audio_device &AudioDevice) start() {
	if C.ma_device_start(audio_device.device) != .success {
		C.ma_device_uninit(audio_device.device)
		panic("Failed to start device!")
	}
}

pub fn (mut audio_device AudioDevice) volume(v f32) {
	audio_device.volume = v
	C.ma_device_set_master_volume(audio_device.device, audio_device.volume)
}

pub fn (mut audio_device AudioDevice) free() {
	if !isnil(audio_device.device) {
		C.ma_device_uninit(audio_device.device)
	}

	// Free audio also
	for mut audio in audio_device.audio {
		audio.free()
	}
}

// Audio FNs
pub fn (mut audio Audio) play() {
	audio.playing = true
}

pub fn (mut audio Audio) pause() {
	audio.playing = false
}

pub fn (mut audio Audio) volume(v f32) {
	audio.volume = v
}

pub fn (mut audio Audio) length() f64 {
	return (audio.pcm_length() / audio.sample_rate()) * f64(1000)
}

pub fn (mut audio Audio) pcm_length() f64 {
	return f64(C.ma_decoder_get_length_in_pcm_frames(audio.decoder))
}

pub fn (mut audio Audio) sample_rate() f64 {
	return f64(audio.decoder.outputSampleRate)
}

pub fn (mut audio Audio) free() {
	if !isnil(audio.decoder) {
		audio.playing = false
		C.ma_decoder_uninit(audio.decoder)
	}
}

// Factory
pub fn make_device() &AudioDevice {
	mut audio_device := &AudioDevice{device: 0, config: C.ma_device_config_init(.playback)}
	
	// Config
	audio_device.config.playback.format = .f32
	audio_device.config.playback.channels = 2
	audio_device.config.sampleRate = 44100
	audio_device.config.dataCallback = voidptr(data_callback)
	audio_device.config.pUserData = audio_device

	// Device
	device := &Device{}

	//
	if C.ma_device_init(C.NULL, &audio_device.config, device) != .success {
		panic("Failed to create device!")
	}


	//
	audio_device.device = device

	audio_device.start()
	audio_device.volume(0.2)

	return audio_device
}