module main

import os
import sokol.sapp
import time as timelib

import framework.logging
import framework.math.time

import game.settings

const (
	used_import = sapp.used_import
	fps = settings.window.record_fps
	frametime = 1000.0 / fps
)

// window_init and window_draw but for recording
pub fn (mut window Window) init_pipe_process() {
	window.proc = os.new_process(os.find_abs_path_of_executable('ffmpeg') or { panic(err) })

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

		"test.mp4" // output
	]

	window.proc.set_args(ffmpeg_arg)
	window.proc.set_redirect_stdio()
	window.proc.run()

	// Init record buffer
	img_size := 1280 * 720 * 4
	window.record_data = unsafe { &byte(malloc(img_size)) }

	logging.info("Pipe Process started!")
}

pub fn (mut window Window) close_pipe_process() {
	window.proc.close()

	// Wait till the process done
	for window.proc.status == .running {}
	timelib.sleep(5 * timelib.second) // Wait for a few second just to make sure

	// Merge audio (for now we'll do it over here instead of doing it on pipe)
	audio_path := window.beatmap.get_audio_path()
	result := os.execute('ffmpeg -i test.mp4 -itsoffset ${settings.gameplay.lead_in_time / 1000.0} -i "${audio_path}" -map 0:0 -map 1:0 -c:v copy -preset ultrafast -filter:a "atempo=${settings.window.speed}" -to ${time.get_time().time / 1000.0} -async 1 "audiotest.mp4" -y')
	println(result)
}

pub fn (mut window Window) pipe_window() {
	// read gl buffer
	C.v_sapp_gl_read_rgba_pixels(0, 0, 1280, 720, window.record_data)

	// hacky but works
	unsafe {
		temp := window.record_data.vbytes(1280 * 720 * 4).bytestr()
		window.proc.stdin_write(temp)	
		temp.free()
	}
}