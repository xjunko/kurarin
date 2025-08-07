module vector

pub const top_left = Origin{
	x:   0
	y:   0
	typ: OriginType.top_left
}
pub const top_centre = Origin{
	x:   0.5
	y:   -1
	typ: OriginType.top_centre
}
pub const top_right = Origin{
	x:   1
	y:   -1
	typ: OriginType.top_right
}

pub const centre_left = Origin{
	x:   0
	y:   0.5
	typ: OriginType.centre_left
}
pub const centre = Origin{
	x:   0.5
	y:   0.5
	typ: OriginType.centre
}
pub const centre_right = Origin{
	x:   1
	y:   0.5
	typ: OriginType.centre_right
}

pub const bottom_left = Origin{
	x:   0
	y:   1
	typ: OriginType.bottom_left
}
pub const bottom_centre = Origin{
	x:   0.5
	y:   1
	typ: OriginType.bottom_centre
}
pub const bottom_right = Origin{
	x:   1
	y:   1
	typ: OriginType.bottom_right
}

pub enum OriginType {
	top_left
	top_centre
	top_right
	centre_left
	centre
	centre_right
	bottom_left
	bottom_centre
	bottom_right
}

pub struct Origin {
	Vector2[f64]
pub mut:
	typ OriginType = OriginType.centre
}

pub fn parse_origin(s string) Origin {
	return match s {
		'TopLeft' {
			top_left
		}
		'TopCentre' {
			top_centre
		}
		'TopRight' {
			top_right
		}
		'CentreLeft' {
			centre_left
		}
		'Centre' {
			centre
		}
		'CentreRight' {
			centre_right
		}
		'BottomLeft' {
			bottom_left
		}
		'BottomCentre' {
			bottom_centre
		}
		'BottomRight' {
			bottom_right
		}
		else {
			println('> Error: Failed to parse origin=${s}')
			top_left
		}
	}
}
