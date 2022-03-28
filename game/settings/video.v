module settings

pub struct Video {
	pub mut:
		record bool
		fps    f64
}

pub fn make_video_settings() Video {
	mut render := Video{
		record: false,
		fps: 60.0
	}

	return render
}