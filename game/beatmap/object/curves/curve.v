module curves

import framework.math.vector { Vector2 }

// nope fuck this, aint going to do curve.
pub struct ICurve {
	pub mut:
		curve 	   []Vector2
		curve_dist []f64
		n_curve    int
		total_dist f64

		point_at(f64)
}

/*
pub fn (mut curve ICurve) init(approx_length f64) {
	curve.n_curve = (approx_length / 4) + 2
	curve.curve = []Vector2{len: curve.n_curve}

	for i in 0 .. curve.n_curve {
		curve.curve = curve.point_at(i / (curve.n_curve - 1))
	}

	curve.curve_dist = []f64{len: curve.n_curve}
	for i in 0 .. curve.n_curve {
		curve.curve_dist[i] = if i == 0 { 0 } else { curve.curve[i].copy().sub(curve.curve[i-1]).len() }
		curve.total_dist += curve.curve_dist[i]
	}
}
*/