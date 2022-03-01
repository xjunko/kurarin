module miniaudio

pub struct AudioDevice {
	pub mut:
		mutex  &C.ma_mutex
		device &Device
		config C.ma_device_config
		audio  []&Audio

		volume f32 = f32(1.0)
}

pub struct Audio {
	pub mut:
		path 	string
		decoder &Decoder

		playing bool
		volume  f32 = f32(1.0)
}

// Mix  (this one is more or less the same thing as larpon's read_and_mix_pcm_frames_f32)
fn read_and_mix_pcm_frames_f32(p_decoder &C.ma_decoder, p_output &f32, frame_count u32, volume f32) u32 {
	mut m_p_output := &f32(0)
	unsafe {
		m_p_output = p_output
	}

	channel_count := u32(2)
	temp := [4096]f32{}
	temp_cap_in_frames := u32((4096 / sizeof(f32)) / channel_count)

	//
	mut total_frames_read := u32(0)
	
	// here goes nothin
	for total_frames_read < frame_count {
		total_frames_remaining := frame_count - total_frames_read
		mut i_sample := u32(0)
		mut frames_read_this_iteration := u32(0)
		mut frames_to_read_this_iteration := temp_cap_in_frames // similar naming ;)

		if frames_to_read_this_iteration > total_frames_remaining {
			frames_to_read_this_iteration = total_frames_remaining
		}

		frames_read_this_iteration = u32(
			C.ma_decoder_read_pcm_frames(
				p_decoder, 
				&temp, 
				frames_to_read_this_iteration
			)
		)

		if frames_read_this_iteration == 0 {
			break
		} 

		// Mix
		for i_sample = 0; i_sample < frames_read_this_iteration * channel_count; i_sample++ {
			idx := total_frames_read * channel_count + i_sample

			unsafe {
				m_p_output[idx] += temp[i_sample] * volume
			}
		}

		total_frames_read += frames_read_this_iteration

		if frames_read_this_iteration < frames_to_read_this_iteration {
			break // EOF
		}
	}

	return total_frames_read
}

// Callback loop
fn data_callback(p_device &C.ma_device, p_output voidptr, p_input voidptr, frame_count u32) {
	mut audio_device := &AudioDevice(p_device.pUserData)

	$if safe_audio ? {
		C.ma_mutex_lock(audio_device.mutex)
	}

	// Play them audio
	for audio in audio_device.audio {
		if !audio.playing || audio.decoder == C.NULL {
			continue
		}

		$if mix_audio ? {
			read_and_mix_pcm_frames_f32(audio.decoder, p_output, frame_count, f32(audio_device.volume * audio.volume))
		} $else {
			C.ma_decoder_read_pcm_frames(audio.decoder, p_output, frame_count)
		}
	}

	$if safe_audio ? {
		C.ma_mutex_unlock(audio_device.mutex)
	}
}

// AudioDevice FNs
[params]
pub struct AddAudioArg {
	pub:
		path string
		speed f64 = 1.0
}

pub fn (mut audio_device AudioDevice) add_audio(arg AddAudioArg) &Audio {
	// Mutex
	$if safe_audio ? {
		C.ma_mutex_lock(audio_device.mutex)
	}

	//
	decoder_config := C.ma_decoder_config_init(.f32, 2, 44100 / arg.speed)
	decoder := Decoder{}
	C.ma_decoder_init_file(arg.path.str, &decoder_config, &decoder)

	mut audio := &Audio{decoder: &decoder, path: arg.path}

	// Add into device
	audio_device.audio << audio

	// Unlock
	$if safe_audio ? {
		C.ma_mutex_unlock(audio_device.mutex)
	}

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
	mut audio_device := &AudioDevice{mutex: 0, device: 0, config: C.ma_device_config_init(.playback)}

	// Having this enable kinda fucks with the audio syncing so... yea ;)
	$if safe_audio ? {
		// Mutex
		mutex := &C.ma_mutex{}
		result := int(C.ma_mutex_init(mutex))

		if result != C.MA_SUCCESS {
			panic("Failed to init AudioDevice's mutex.")
		}

		audio_device.mutex = mutex
	}
	
	// Config
	audio_device.config.playback.format = .f32
	audio_device.config.playback.channels = 2
	audio_device.config.sampleRate = 44100
	audio_device.config.dataCallback = voidptr(data_callback)
	audio_device.config.pUserData = audio_device

	// Device
	device := &Device{}

	
	if C.ma_device_init(C.NULL, &audio_device.config, device) != .success {
		panic("Failed to create device!")
	}


	//
	audio_device.device = device

	audio_device.start()
	audio_device.volume(0.5)

	return audio_device
}