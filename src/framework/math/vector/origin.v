module vector

pub const (
	top_left = Origin{
		x: 0
		y: 0
		typ: OriginType.top_left
	}
	top_centre = Origin{
		x: 0.5
		y: -1
		typ: OriginType.top_centre
	}
	top_right = Origin{
		x: 1
		y: -1
		typ: OriginType.top_right
	}

	centre_left = Origin{
		x: 0
		y: 0.5
		typ: OriginType.centre_left
	}
	centre = Origin{
		x: 0.5
		y: 0.5
		typ: OriginType.centre
	}
	centre_right = Origin{
		x: 1
		y: 0.5
		typ: OriginType.centre_right
	}

	bottom_left = Origin{
		x: 0
		y: 1
		typ: OriginType.bottom_left
	}
	bottom_centre = Origin{
		x: 0.5
		y: 1
		typ: OriginType.bottom_centre
	}
	bottom_right = Origin{
		x: 1
		y: 1
		typ: OriginType.bottom_right
	}
)

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
			vector.top_left
		}
		'TopCentre' {
			vector.top_centre
		}
		'TopRight' {
			vector.top_right
		}
		'CentreLeft' {
			vector.centre_left
		}
		'Centre' {
			vector.centre
		}
		'CentreRight' {
			vector.centre_right
		}
		'BottomLeft' {
			vector.bottom_left
		}
		'BottomCentre' {
			vector.bottom_centre
		}
		'BottomRight' {
			vector.bottom_right
		}
		else {
			println('> Error: Failed to parse origin=${s}')
			vector.top_left
		}
	}
}
