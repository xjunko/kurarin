module ffmpeg

import os
import x.json2 as json

pub struct Metadata {
	pub mut:
		width  f64
		height f64
		fps    f64
}

pub fn load_metadata(path string) &Metadata {
	mut metadata := &Metadata{}

	output := os.execute("ffprobe -i '${path}' -select_streams v:0 -show_entries stream -show_entries format -of json -loglevel quiet").output
	mut data := (json.raw_decode(output) or { panic(err) }).as_map() 

	video_stream := ((data['streams'] or { panic("JSON: Field does not exists.") }).as_map()["0"] or { panic("JSON: Field does not exists.") }).as_map()

	// parse shit
	metadata.width = (video_stream["width"] or { panic("JSON: Field does not exists.") }).f64()
	metadata.height = (video_stream["height"] or { panic("JSON: Field does not exists.") }).f64()
	metadata.fps = parse_rate((video_stream["r_frame_rate"] or { panic("JSON: Field does not exists.") }).str())

	return metadata
}	

pub fn parse_rate(rate string) f64 {
	items := rate.split('/')

	mut fps := items[0].f64()

	if items.len > 1 {
		div := items[1].f64()
		fps /= div
	}

	return fps
}

// fn init() {
// 	_ := load_metadata("/run/media/junko/2nd/Projects/v-ground/video-testing/video2.mp4")
// 	mut video := load_video("/run/media/junko/2nd/Projects/v-ground/video-testing/video2.mp4")
// 	video.initialize_video_data()
// 	video.initialize_ffmpeg()
// 	video.update()

// 	println(video)
// 	println(video.buffer.len)
// }