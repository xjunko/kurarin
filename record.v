module main

import game.settings // Load this first

import os
import sokol.sapp
import time as timelib

import framework.audio
import framework.logging


const (
	used_import = sapp.used_import
	fps = settings.global.window.record_fps
	frametime = 1000.0 / fps
)

// window_init and window_draw but for recording
pub fn (mut window Window) init_video_pipe_process() {
	window.video_proc = os.new_process(os.find_abs_path_of_executable('ffmpeg') or { panic(err) })

	// ffmpeg_arg := [
	// 	"-r", "${fps}", "-f", "rawvideo", "-pix_fmt", "rgba", "-s", "1280x720", "-i", "-", "-vf", "vflip", // Video
	// 	// "-vcodec", "rawvideo",
	// 	// "-profile:v", "high",
	// 	"-preset", "faster",
	// 	"-crf", "15",
	// 	// "-i", '"${window.beatmap.get_audio_path()}"'.replace("!", "\\!"), // Beatmap song
	// 	"-movflags", "+write_colr", // yes
	// 	"test.mp4", "-y" // Output
	// ]

	ffmpeg_arg := [
		"-y",

		"-f", "rawvideo",
		"-vcodec", "rawvideo",
		"-s", "1280x720",
		"-pix_fmt", "rgba",
		"-r", fps.str(),
		"-i", "-",

		"-vf", "vflip",
		"-preset", "faster",
		"-crf", "15",
		"-c:v", "libx264"
		"-color_range", "1",
		"-colorspace", "1",
		"-color_trc", "1",
		"-color_primaries", "1",
		"-movflags", "+write_colr",
		"-pix_fmt", "yuv420p"

		"temp.mp4" // output
	]

	window.video_proc.set_args(ffmpeg_arg)
	window.video_proc.set_redirect_stdio()
	window.video_proc.run()

	// Init record buffer
	img_size := 1280 * 720 * 4
	window.record_data = unsafe { &byte(malloc(img_size)) }

	logging.info("VideoPipe Process started!")
}

pub fn (mut window Window) init_audio_pipe_process() {
	audio_buffer_size := audio.get_required_buffer_size_for_mixer(1.0 / settings.global.window.record_fps)
	window.audio_data = []byte{len: audio_buffer_size}

	// Create the process
	window.audio_proc = os.new_process(
		os.find_abs_path_of_executable("ffmpeg") or { panic(err) }
	)

	ffmpeg_arg := [
		"-y",
		"-f", "f32le",
		"-acodec", "pcm_f32le",
		"-ar", "48000",
		"-ac", "2",
		"-i", "-",

		"-nostats",
		"-vn",
		"temp.mp3"
	]

	window.audio_proc.set_args(ffmpeg_arg)
	window.audio_proc.set_redirect_stdio()
	window.audio_proc.run()

	logging.info("AudioPipe Process started!")
}

pub fn (mut window Window) close_pipe_process() {
	window.video_proc.close()
	window.audio_proc.close()

	// Wait till the process done
	for window.video_proc.status == .running {}
	for window.audio_proc.status == .running {}
	timelib.sleep(5 * timelib.second) // Wait for a few second just to make sure

	// Merge audio (for now we'll do it over here instead of doing it on pipe)
	audio_path := "temp.mp3" 
	result := os.execute('ffmpeg -i temp.mp4 -i "${audio_path}" -map 0:0 -map 1:0 -c:v copy -preset ultrafast -async 1 "output.mp4" -y')
	println(result)
}

pub fn (mut window Window) pipe_window() {
	// read gl buffer
	C.v_sapp_gl_read_rgba_pixels(0, 0, 1280, 720, window.record_data)

	// hacky but works
	unsafe {
		temp := window.record_data.vbytes(1280 * 720 * 4).bytestr()
		window.video_proc.stdin_write(temp)	
		temp.free()
	}
}

pub fn (mut window Window) pipe_audio() {
	audio.get_mixer_data(mut window.audio_data)

	unsafe {
		temp := window.audio_data.bytestr()
		window.audio_proc.stdin_write(temp)
		temp.free()
	}
}