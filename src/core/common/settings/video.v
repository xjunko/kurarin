module settings

pub struct Video {
pub mut:
	record     bool
	fps        f64
	update_fps f64
}

pub fn Video.new() Video {
	return Video{
		record: false
		fps: 60.0
		update_fps: 480
	}
}
