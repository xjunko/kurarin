module settings

pub struct Video {
	pub mut:
		record     bool
		fps        f64
		update_fps f64
}

pub fn make_video_settings() Video {
	mut render := Video{
		record: false,
		fps: 60.0,
		update_fps: 480
	}

	return render
}