module vector

pub const (
	top_left = Vector2{0, 0}
	top_centre = Vector2{0.5, -1}
	top_right = Vector2{1, -1}

	
	centre_left = Vector2{0, 0.5}
	centre = Vector2{0.5, 0.5}
	centre_right = Vector2{1, 0.5}
	

	bottom_left = Vector2{0, 1}
	bottom_centre = Vector2{0.5, 1}
	bottom_right = Vector2{1, 1}
)

pub fn parse_origin(s string) Vector2 {
	return match s {
		'TopLeft' { top_left }
		'TopCentre' { top_centre }
		'TopRight' { top_right }

		'CentreLeft' { centre_left }
		'Centre' { centre }
		'CentreRight' { centre_right}

		'BottomLeft' { bottom_left }
		'BottomCentre' { bottom_centre }
		'BottomRight' { bottom_right }

		else {
			println("> Error: Failed to parse origin=${s}")
			top_left
		}
	}
}