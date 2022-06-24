module audio

import framework.logging

import game.settings

const (
	global = &GlobalMixer{}
)

pub struct GlobalMixer{
	pub mut:
		master C.HSTREAM
}

// Start Bass and shit
fn init() {
	playback_buffer_length := int(100)
	device_buffer_length := int(10)
	update_period := int(5)
	dev_update_period := int(10)

	C.BASS_SetConfig(C.BASS_CONFIG_DEV_NONSTOP, 1)
	C.BASS_SetConfig(C.BASS_CONFIG_VISTA_TRUEPOS, 0)
	C.BASS_SetConfig(C.BASS_CONFIG_BUFFER, playback_buffer_length)
	C.BASS_SetConfig(C.BASS_CONFIG_UPDATEPERIOD, update_period)
	C.BASS_SetConfig(C.BASS_CONFIG_DEV_BUFFER, device_buffer_length)
	C.BASS_SetConfig(C.BASS_CONFIG_DEV_PERIOD, dev_update_period)
	C.BASS_SetConfig(68, 1)

	mut device_id := -1
	mut mixer_flags := C.BASS_MIXER_NONSTOP

	if settings.global.video.record {
		logging.info("BASS in recording mode")
		device_id = 0
		mixer_flags |= C.BASS_SAMPLE_FLOAT | C.BASS_STREAM_DECODE
	}

	if C.BASS_Init(device_id, 48000, 0, 0, 0) != 0 {
		logging.info("BASS Started!")

		// Mixer
		master_mixer := C.BASS_Mixer_StreamCreate(48000, 2, mixer_flags)
		C.BASS_ChannelSetAttribute(master_mixer, C.BASS_ATTRIB_BUFFER, 0)
		C.BASS_ChannelSetDevice(master_mixer, C.BASS_GetDevice())

		C.BASS_ChannelPlay(master_mixer, 0)

		// Point global to that mixer
		unsafe {
			mut g_mixer := global
			g_mixer.master = master_mixer
		}
	} else {
		logging.error("Failed to start BASS!")
	}
}


// Just a test ignore this
// pub fn start_piping_audio() {
// 	// Some testing
// 	go fn() {
// 		audio_buffer_size := get_required_buffer_size_for_mixer(1 / 1000.0)
// 		mut audio_buffer := []byte{len: audio_buffer_size}

// 		// process to pipe to
// 		mut process := os.new_process(
// 			os.find_abs_path_of_executable("ffmpeg") or { panic(err) }
// 		)

// 		ffmpeg_arg := [
// 			"-y",
// 			"-f", "f32le",
// 			"-acodec", "pcm_f32le",
// 			"-ar", "48000",
// 			"-ac", "2",
// 			"-i", "-",

// 			"-nostats", //hide audio encoding statistics because video ones are more important
// 			"-vn",
// 			"temp.mp3"
// 		]
// 		process.set_args(ffmpeg_arg)
// 		process.set_redirect_stdio()
// 		process.run()

// 		audio_delta := 1000.0 / 1000.0
// 		mut audio_delta_count := 0.0

// 		for {
// 			audio_delta_count += audio_delta
// 			for audio_delta_count >= audio_delta {
// 				get_mixer_data(mut audio_buffer)
// 				unsafe {
// 					temp := audio_buffer.bytestr()
// 					process.stdin_write(temp)
// 					temp.free()
// 					println("piped")
// 				}
// 				audio_delta_count -= audio_delta
// 			}

// 		}
// 	}()
// }