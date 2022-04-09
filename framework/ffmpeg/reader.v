module ffmpeg

import os
import math

import framework.logging

pub struct FFmpegReader {
	mut:
		video_path         string
		target_resolution  [2]f64 = [1280.0, 720.0]!

		process 		  &os.Process = voidptr(0)
		ok                bool

	pub mut:
		buffer 	  []byte

		// Info
		metadata  &Metadata = voidptr(0)
}

pub fn (mut reader FFmpegReader) initialize_video_data() {
	if !os.exists(reader.video_path) {
		logging.error("Tried to read unexisting video file.")
	}

	// Resize video to fit target_resolution
	mut ratio := reader.target_resolution[0] / reader.metadata.width

	// Make sure both sides fits the screen
	for (reader.metadata.height * ratio) < reader.target_resolution[1] {
		ratio += 0.05
	}

	// Resize
	reader.metadata.width *= ratio
	reader.metadata.height *= ratio
}

pub fn (mut reader FFmpegReader) initialize_ffmpeg() {
	reader.process = os.new_process(os.find_abs_path_of_executable("ffmpeg") or { panic(err) })

	ffmpeg_arg := [
		"-i", reader.video_path,
		"-f", "rawvideo",
		"-pix_fmt", "rgba",
		"-ss", "0:0:0",
		"-vf", "scale=${reader.metadata.width}:${reader.metadata.height}"
		"-"
	]

	reader.process.set_args(ffmpeg_arg)
	reader.process.set_redirect_stdio()
	reader.process.run()
}

pub fn (mut reader FFmpegReader) update() {
	expected_data_length := int(reader.metadata.width * reader.metadata.height * 4)
	mut remaining := expected_data_length

	unsafe {
		reader.buffer.clear()

		// TODO: I dont like this, streaming the buffer is kinda bad tbh
		for reader.buffer.len < expected_data_length {
			data, amount_of_bytes := os.fd_read(reader.process.stdio_fd[1], math.min(remaining, 4096 * 6))
			remaining -= amount_of_bytes
			reader.buffer << data.bytes()
			data.free()
		}
	}
}

pub fn load_video(path string) &FFmpegReader {
	mut reader := &FFmpegReader{video_path: path}
	reader.metadata = load_metadata(path)

	return reader
}