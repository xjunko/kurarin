// Copy pasted straight from the old code since
// this code isnt that bad, it just eats alot of ram
// (i dont want to do this part of the codebase again, im bad at math ;P)

module curves

import framework.math.vector

pub struct SliderCurve {
	pub mut:
		curves []Curve
		sections []f64
		length f64
}

pub fn new_slider_curve(typp string, points []vector.Vector2) SliderCurve {
	mut curves_list := []Curve{}
	mut length := f64(0.0)
	mut typ := typp

	if points.len < 3 {
		typ = "L"
	}

	match typ {
		"L" {
			for i := 1; i < points.len; i++ {
				c := curves.make_linear(points[i-1], points[i])
				curves_list << c
				length += c.get_length()
			}
		}
		"B" {
			mut last_index := 0
			for i, p in points {
				if i == points.len - 1 || points[i + 1] == p {
					c := curves.make_bezier(points[last_index .. i + 1])
					curves_list << c
					length += c.get_length()
					last_index = i + 1
				}
			}
		}
		"P" {
			c := curves.make_circ_arc(points[0], points[1], points[2])
			curves_list << c
			length += c.get_length()
		}
		else {
			println("> THE FUCK: Slider type: ${typ}")
		}
	}
	mut sections := []f64{len: curves_list.len + 1}
	sections[0] = 0.0
	mut prev := 0.0

	if curves_list.len > 0 {
		for i := 0; i < curves_list.len; i++ {
			prev += curves_list[i].get_length() / length
			sections[i+1] = prev
		}
	}

	return SliderCurve{curves_list, sections, length}
}

pub fn (slider SliderCurve) point_at(time f64) vector.Vector2 {
	if slider.curves.len == 1 {
		return slider.curves[0].point_at(time)
	} else {
		t := slider.sections[slider.sections.len - 1] * time
		for i := 1; i < slider.sections.len; i++ {
			if time <= slider.sections[i] || i == slider.sections.len - 1 {
				prc := (t - slider.sections[i - 1]) / (slider.sections[i] - slider.sections[i - 1])
				return slider.curves[i - 1].point_at(prc)
			}
		}
	}

	return vector.Vector2{512/2, 384/2}
}

pub fn (slider SliderCurve) get_length() f64 {
	return slider.length
}