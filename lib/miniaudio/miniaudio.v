// Copyright(C) 2019 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
// miniaudio (https://github.com/dr-soft/miniaudio) by David Reid (dr-soft)
// is licensed under the unlicense and, are thus, in the publiic domain.
module miniaudio

/*
* Miniaudio public API
*/
pub fn device() &Device {
	mut d := &Device{
		context: 0
		mutex: 0
		device: 0
		vol: 1.0
		initialized: false
	}
	d.init_context()
	d.init_mutex()
	d.device_config = C.ma_device_config_init(DeviceType.playback)
	d.device_config.playback.format = int(Format.f32)
	d.device_config.playback.channels = 2
	d.device_config.sampleRate = 44100 // Affects global music speed
	d.device_config.dataCallback = voidptr(data_callback)
	d.device_config.pUserData = d
	d.init_device()
	$if debug {
		println('INFO ' + @MOD + '::' + @FN + ' Setting device ' +
			ptr_str(d.device_config.pUserData) + ' as callback data')
	}
	d.start()
	
	return d
}

[args]
pub struct SoundArg {
	filename string
	speed    f64 = 1.0
}

pub fn sound(arg SoundArg) &Sound {
	decoder_config := C.ma_decoder_config_init(int(Format.f32), 2, 44100 / arg.speed)
	// Init decoder
	decoder := &C.ma_decoder{}
	result := int(C.ma_decoder_init_file(arg.filename.str, &decoder_config, decoder))
	if result != C.MA_SUCCESS {
		eprintln('ERROR ' + @MOD + '::' + @FN +
			' Failed to init decoder from "$arg.filename" (ma_decoder_init_file ${translate_error_code(result)} )')
		exit(1)
	}
	$if debug {
		println('INFO ' + @MOD + '::' + @FN + ' Initialized decoder ' + ptr_str(decoder))
	}
	ab := audio_buffer(decoder)
	s := &Sound{
		audio_buffer: ab
	}
	$if debug {
		println('INFO ' + @MOD + '::' + @FN + ' Initialized Sound ' + ptr_str(s))
	}
	return s
}

// sound_from_memory creates a sound object from the provided byte array
pub fn sound_from_memory(data []byte) &Sound {
	decoder_config := C.ma_decoder_config_init(int(Format.f32), 2, 44100)
	// Init decoder
	decoder := &C.ma_decoder{}
	result := int(C.ma_decoder_init_memory(data.data, data.len, &decoder_config, decoder))
	
	if result != C.MA_SUCCESS {
		eprintln('ERROR ' + @MOD+'::' + @FN + ' Failed to init decoder from data (ma_decoder_init_memory ${translate_error_code(result)} )')
		exit(1)
	}
	
	$if debug {
		println('INFO ' + @MOD+'::' + @FN + ' Initialized decoder ' + ptr_str(decoder))
	}

	ab := audio_buffer(decoder)
	s := &Sound{
		audio_buffer: ab
	}
	
	$if debug {
		println('INFO ' + @MOD+'::' + @FN + ' Initialized Sound ' + ptr_str(s))
	}
	return s
}

fn audio_buffer(decoder &C.ma_decoder) &AudioBuffer {
	ab := &AudioBuffer{
		volume: 1.0
		decoder: decoder
		// mutex: sync.new_mutex()
	}
	$if debug {
		println('INFO ' + @MOD + '::' + @FN + ' Initialized AudioBuffer ' + ptr_str(ab))
	}
	return ab
}

/*
* Device
*/
pub struct Device {
mut:
	context        &C.ma_context
	context_config C.ma_context_config
	device         &C.ma_device
	device_config  C.ma_device_config
	mutex          &C.ma_mutex
	initialized    bool
	buffers        map[string]&AudioBuffer
	vol            f64 // Master volume for the device
}

pub fn (mut d Device) volume(volume f64) {
	// C.ma_mutex_lock(d.mutex)
	d.vol = volume
	// C.ma_mutex_unlock(d.mutex)
}

fn (mut d Device) init_context() {
	// Init audio context
	context := &C.ma_context{
		logCallback: 0
	}
	d.context_config = C.ma_context_config_init()
	d.context_config.logCallback = voidptr(log_callback)
	result := int(C.ma_context_init(C.NULL, 0, &d.context_config, context))
	if result != C.MA_SUCCESS {
		eprintln('ERROR ' + @MOD + '::' + @FN +
			' Failed to initialize audio context.  (ma_context_init ${translate_error_code(result)} ')
		exit(1)
	}
	d.context = context
	$if debug {
		println('INFO ' + @MOD + '::' + @FN + ' Initialized context ' + ptr_str(d.context))
	}
}

fn (mut d Device) init_mutex() {
	// We need a valid context
	if d.context == 0 {
		return
	}
	// Init audio mutex
	mutex := &C.ma_mutex{}
	result := int(C.ma_mutex_init(d.context, mutex))
	if result != C.MA_SUCCESS {
		eprintln('ERROR ' + @MOD + '::' + @FN +
			' Failed to initialize audio mutex.  (ma_mutex_init ${translate_error_code(result)} ')
		exit(1)
	}
	d.mutex = mutex
	$if debug {
		println('INFO ' + @MOD + '::' + @FN + ' Initialized mutex ' + ptr_str(d.mutex))
	}
}

fn (mut d Device) init_device() {
	// Init audio device from device_config
	device := &C.ma_device{
		pUserData: 0
	}
	result := int(C.ma_device_init(d.context, &d.device_config, device))
	if result != C.MA_SUCCESS {
		eprintln('ERROR ' + @MOD + '::' + @FN +
			' Failed to initialize device (ma_device_init ${translate_error_code(result)})')
		exit(1)
	}
	d.device = device
	$if debug {
		println('INFO ' + @MOD + '::' + @FN + ' Initialized device ' + ptr_str(d.device))
	}
	d.initialized = true
	// println(d.device)
}

pub fn (mut d Device) start() {
	if !d.initialized {
		return
	}
	if !d.is_started() {
		$if debug {
			println('INFO ' + @MOD + '::' + @FN + ' Starting device ' + ptr_str(d.device))
		}
		result := int(C.ma_device_start(d.device))
		if result != C.MA_SUCCESS {
			eprintln('ERROR ' + @MOD + '::' + @FN +
				' failed to start device playback (ma_device_start ${translate_error_code(result)})')
			d.free()
			exit(1)
		}
		$if debug {
			println('INFO ' +@MOD +'::' + @FN + ' Started device')
		}
	} else {
		$if debug {
			println('INFO ' + @MOD + '::' + @FN + ' Device already started')
		}
	}
}

pub fn (mut d Device) add(id string, s Sound) {
	C.ma_mutex_lock(d.mutex)
	$if debug {
		println('INFO ' + @MOD + '::' + @FN + ' Adding sound ' + id + ':' + ptr_str(s) +
			' with audio buffer:' + ptr_str(s.audio_buffer) + ' to device ' + ptr_str(d))
	}
	if id in d.buffers {
		println('WARNING ' + @MOD + '::' + @FN + ' ' + id + ' is already added')
	}
	d.buffers[id] = s.audio_buffer
	C.ma_mutex_unlock(d.mutex)
}

pub fn (d Device) is_started() bool {
	if !d.initialized {
		return false
	}
	if C.ma_device_is_started(d.device) {
		return true
	}
	return false
}

/*
pub fn (d Device) pos() f64 {
    C.ma_decoder_read_pcm_frames
}*/

/*
pub fn (d mut Device) play() {

    if !d.initialized { return }

    if d.is_started() {
        d.stop()
    }

    d.seek_frame(0)

    d.start()
}*/

pub fn (mut d Device) stop() {
	if !d.initialized {
		return
	}
	mut result := C.MA_SUCCESS
	if d.is_started() {
		$if debug {
			println('INFO ' + @MOD + '::' + @FN + ' Stopping device ' + ptr_str(d.device))
		}
		result = int(C.ma_device_stop(d.device))
		if result != C.MA_SUCCESS {
			eprintln('ERROR ' + @MOD + '::' + @FN +
				' failed to stop device (ma_device_stop ${translate_error_code(result)})')
			d.free()
			exit(1)
		}

		// Produces a parsing error: https://github.com/vlang/v/issues/10243
		/*$if debug {
			println('INFO ' + @MOD+'::' + @FN + ' Device stopped')
		}*/
	} else {
		$if debug {
			println('INFO ' + @MOD + '::' + @FN + ' Device not started')
		}
	}
}

pub fn (mut d Device) free() {
	$if debug {
		println('INFO ' + @MOD + '::' + @FN)
	}
	d.stop()
	d.initialized = false
	C.ma_device_uninit(d.device)
	// C.ma_decoder_uninit(d.decoder)
	C.ma_context_uninit(d.context)
	C.ma_mutex_uninit(d.mutex)
	d.context = &C.ma_context(0)
	d.mutex = &C.ma_mutex(0)
	d.device = &C.ma_device(0)
	// d.decoder = 0
}

/*
* Callbacks
*/
fn read_and_mix_pcm_frames_f32(p_decoder &C.ma_decoder, p_output &f32, frameCount u32, master_volume f64, local_volume f64) u32 {
	// The way mixing works is that we just read into a temporary buffer, then take the contents of that buffer and mix it with the
	// contents of the output buffer by simply adding the samples together. You could also clip the samples to -1..+1, but I'm not
	// doing that in this example.
	mut m_p_output := &f32(0)
	unsafe {
		m_p_output = p_output
	}
	channel_count := u32(2)
	temp := [4096]f32{}
	temp_cap_in_frames := u32((4096 / sizeof(f32)) / channel_count)
	mut total_frames_read := u32(0)
	for total_frames_read < frameCount {
		mut i_sample := u32(0)
		mut frames_read_this_iteration := u32(0)
		total_frames_remaining := frameCount - total_frames_read
		mut frames_to_read_this_iteration := temp_cap_in_frames
		if frames_to_read_this_iteration > total_frames_remaining {
			frames_to_read_this_iteration = total_frames_remaining
		}
		frames_read_this_iteration = u32(C.ma_decoder_read_pcm_frames(p_decoder, &temp,
			frames_to_read_this_iteration))
		if frames_read_this_iteration == 0 {
			break
		}
		// Mix the frames together.
		for i_sample = 0; i_sample < frames_read_this_iteration * channel_count; i_sample++ {
			idx := total_frames_read * channel_count + i_sample
			// println('m:'+master_volume.str()+' l:'+local_volume.str())
			unsafe {
				m_p_output[idx] += temp[i_sample] * f32(master_volume * local_volume)
			}
		}
		total_frames_read += frames_read_this_iteration
		if frames_read_this_iteration < frames_to_read_this_iteration {
			break
		}
		// Reached EOF.
	}
	return total_frames_read
}

fn log_callback(p_context &C.ma_context, p_device &C.ma_device, logLevel u32, message &char) {
	unsafe {
		eprintln('ERROR ' + @MOD + tos3(message))
	}

	exit(1)
}

fn data_callback(p_device &C.ma_device, p_output voidptr, p_input voidptr, frame_count u32) {
	// Most of this function is heavily inspired, if not outright copied
	// from raylib: https://github.com/raysan5/raylib/blob/c20ccfe274f94d29dcf1a1f84048a57d56dedce6/src/raudio.c#L275
	d := &Device(p_device.pUserData)
	if d == C.NULL {
		return
	}
	if !d.initialized {
		return
	}
	// println('Callback device '+ptr_str(d)+'')
	// Mixing is basically just an accumulation, we need to initialize the output buffer to 0
	// C.memset(p_output, 0, frame_count*p_device.playback.channels*C.ma_get_bytes_per_sample(p_device.playback.format))
	C.ma_mutex_lock(d.mutex)
	master_volume := d.vol
	// println('Callback buffers: '+d.buffers.size.str())

	// For some reason on the latest V, doing a for loop on a map
	// returns back a bad struct (at least on msvc on Windows)
	/*
	for key, audio_buffer in d.buffers {
		println("$key $audio_buffer")
		// mut ab := audio_buffer
		// ab.mutex.lock()
		// println('ab: '+audio_buffer.playing.str())
		if !audio_buffer.playing || audio_buffer.paused {
			continue
		}
		// println('AudioBuffer at '+ptr_str(audio_buffer))
		p_decoder := audio_buffer.decoder
		if p_decoder == C.NULL {
			continue
		}
		// println('Using decoder at '+ptr_str(p_decoder))
		// println(p_decoder.outputFormat.str()+' '+p_decoder.outputChannels.str()+' '+p_decoder.outputSampleRate.str())
		/*frames_read :=*/
		read_and_mix_pcm_frames_f32(p_decoder, p_output, frame_count, master_volume, audio_buffer.volume)
		/*frames_read :=*/ // C.read_and_mix_pcm_frames_f32(p_decoder, p_output, frame_count)
		/*frames_read :=*/ // C.ma_decoder_read_pcm_frames(p_decoder, p_output, frame_count)
		// ab.mutex.unlock()
	}*/

	keys := d.buffers.keys()
	for key in keys {
		audio_buffer := d.buffers[key]
		// mut ab := audio_buffer
		// ab.mutex.lock()
		// println('ab: '+audio_buffer.playing.str())
		if !audio_buffer.playing || audio_buffer.paused {
			continue
		}
		// println('AudioBuffer at '+ptr_str(audio_buffer))
		p_decoder := audio_buffer.decoder
		if p_decoder == C.NULL {
			continue
		}
		// println('Using decoder at '+ptr_str(p_decoder))
		// println(p_decoder.outputFormat.str()+' '+p_decoder.outputChannels.str()+' '+p_decoder.outputSampleRate.str())
		// frames_read :=
		read_and_mix_pcm_frames_f32(p_decoder, p_output, frame_count, master_volume, audio_buffer.volume)
		// frames_read := // C.read_and_mix_pcm_frames_f32(p_decoder, p_output, frame_count)
		// frames_read := // C.ma_decoder_read_pcm_frames(p_decoder, p_output, frame_count)
		// ab.mutex.unlock()
	}

	C.ma_mutex_unlock(d.mutex)
}

/*
pub fn sound_from(filename string) Sound {

}*/

/*
* Interfaces
*/

// interface HasAudioBufferGetter {
// audio_buffer()              AudioBuffer
// }
/*
* Sound
*/
struct Sound {
mut:
	audio_buffer &AudioBuffer
}

pub fn (mut s Sound) play() {
	s.audio_buffer.playing = true
}

pub fn (mut s Sound) pause() {
	s.audio_buffer.playing = false
}

pub fn (s Sound) length() f64 {
	if s.audio_buffer == 0 {
		return f64(0)
	}
	return s.audio_buffer.length()
}

pub fn (s Sound) pcm_frames() u64 {
	if s.audio_buffer == 0 {
		return u64(0)
	}
	return s.audio_buffer.pcm_frames()
}

pub fn (s Sound) sample_rate() u32 {
	if s.audio_buffer == 0 {
		return u32(0)
	}
	return s.audio_buffer.sample_rate()
}

pub fn (mut s Sound) volume(volume f64) {
	if s.audio_buffer == 0 {
		return
	}
	mut value := volume
	if value < 0 {
		value = 0.0
	}
	if value > 1 {
		value = 1.0
	}
	// $if debug { println('Sound '+ptr_str(s)+' -> volume: '+value.str()) }
	s.audio_buffer.set_volume(value)
}

pub fn (mut s Sound) seek(ms f64) {
	if s.audio_buffer == 0 {
		return
	}
	s.audio_buffer.seek(ms)
}

/*
fn (s Sound) audio_buffer() AudioBuffer {
    return s.audio_buffer
}*/

/*
* Stream
*/

struct Stream {
mut:
	audio_buffer AudioBuffer
}

fn (s Stream) audio_buffer() AudioBuffer {
	return s.audio_buffer
}

/*
* AudioBuffer
*/

struct AudioBuffer {
mut:
	// dsp                         C.ma_pcm_converter // PCM data converter
	decoder &C.ma_decoder
	volume  f64 	   // Audio buffer volume
	pitch   f64  = 1.0 // Audio buffer pitch
	playing bool
	paused  bool
	// TODO looping                     bool
	// TODO loops                       int
	// TODO is_stream                   bool
	// TODO is_static                   bool
	// TODO is_sub_buffer_processed     [2]bool
	// TODO mutex                       sync.Mutex
	// frame_cursor_pos            u64 // Frame cursor position
	// buffer_size_in_frames       u64 // Total buffer size in frames
	// total_frames_processed      u64 // Total frames processed in this buffer (required for play timming)
	// buffer                      byteptr // Data buffer, on music stream keeps filling
}

pub fn (mut ab AudioBuffer) set_volume(volume f64) {
	// ab.mutex.lock()
	mut value := volume
	if value < 0 {
		value = 0.0
	}
	if value > 1 {
		value = 1.0
	}
	// $if debug { println('AudioBuffer '+ptr_str(ab)+' -> volume: '+value.str()) }
	ab.volume = value
	// ab.mutex.unlock()
}

pub fn (mut ab AudioBuffer) seek(ms f64) {
	if ms < 0 || ms > ab.length() {
		return
	}
	$if debug {
		println('INFO ' + @MOD + '::' + @FN + ' AudioBuffer ' + ptr_str(ab) +
			' seek to millisecond ' + ms.str())
	}
	ab.seek_frame(u64((ms / f64(1000)) * f64(ab.sample_rate())))
}

pub fn (mut ab AudioBuffer) seek_frame(pcm_frame u64) {
	ab.playing = false
	if pcm_frame < 0 || pcm_frame > ab.pcm_frames() {
		return
	}
	$if debug {
		println('INFO ' + @MOD + '::' + @FN + ' AudioBuffer ' + ptr_str(ab) + ' seek PCM frame ' +
			pcm_frame.str() + '/' + ab.pcm_frames().str())
	}
	result := int(C.ma_decoder_seek_to_pcm_frame(ab.decoder, pcm_frame))
	if result != C.MA_SUCCESS {
		eprintln('ERROR ' + @MOD + '::' + @FN +
			': failed to seek device to PCM frame $pcm_frame (ma_decoder_seek_to_pcm_frame ${translate_error_code(result)})')
		// d.free() // TODO
		exit(1)
	}
	ab.playing = true
}

pub fn (ab AudioBuffer) length() f64 {
	pcm_frames := f64(ab.pcm_frames())
	sample_rate := f64(ab.sample_rate())
	return (pcm_frames / sample_rate) * f64(1000)
}

pub fn (ab AudioBuffer) pcm_frames() u64 {
	return u64(C.ma_decoder_get_length_in_pcm_frames(ab.decoder))
}

pub fn (ab AudioBuffer) sample_rate() u32 {
	return ab.decoder.outputSampleRate
}
