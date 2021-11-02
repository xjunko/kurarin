module window


// import os
// import sokol.sapp
// import game.math.resolution



pub struct VideoWriter {
	pub mut:
		ready bool
		path  string
		data  []byte
		size  int
		frame int
}

/*
pub fn make_video_writer(path string) &VideoWriter {
	mut writer := &VideoWriter{path: path}
	writer.size = int(resolution.global.width * resolution.global.height * 4)
	writer.data = []byte{len: writer.size, init: 0}
	
	return writer
}

pub fn (mut writer VideoWriter) write() {
	println("> Writing frame: ${writer.frame}")
	// get data then store it into the shit
	C.v_sapp_gl_read_rgba_pixels(0, 0, resolution.global.width, resolution.global.height, writer.data.data)
	
	// save to ppm format
	mut f_out := os.create(os.join_path(writer.path, '${writer.frame}.ppm')) or { panic(err) }
	f_out.writeln('P3') or {}
	f_out.writeln('${resolution.global.width} ${resolution.global.height}') or {}
	f_out.writeln('255') or {}

	for i := resolution.global.height - 1; i >= 0; i-- {
		for j := 0; j < resolution.global.width; j++ {
			idx := int(i * resolution.global.width * 4 + j * 4)
			f_out.write_string('${writer.data[idx]} ${writer.data[idx + 1]} ${writer.data[idx + 2]} ') or {}
		}
	}

	f_out.close()
	writer.frame++
}



pub fn save_raw_pixels_into_file(filename string) {
	w := int(resolution.global.width)
	h := int(resolution.global.height)
	size := w * h * 4 // RGBA?
	mut pixels_data := []byte{len: size, init: 0}

	unsafe {
		C.v_sapp_gl_read_rgba_pixels(0, 0, w, h, &pixels_data[0])
	}

	println("YOOOO: ${pixels_data.len}bytes")

	// save the shit
	mut f_out := os.create("rawpixels.raw") or { panic(err) }
	f_out.write(pixels_data) or {panic(err)}
	f_out.close()

	unsafe {
		pixels_data.free()
	}
}


*/