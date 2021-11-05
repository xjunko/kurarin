module curves

import framework.math.vector { Vector2 }

pub fn catmul_rom(v1 Vector2, v2 Vector2, v3 Vector2, v4 Vector2, amount f64) Vector2 {
	amount_squared := amount * amount
	amount_cubed := amount_squared * amount
	
	/*
	return (
		(
			v2.multiply(f64(2.0))
			.add(v3.sub(v1).multiply(amount))
			.add(
				v1.multiply(2.0).sub(v2.multiply(5.0)).add(v3.multiply(4.0)).sub(v4)
				)
			.multiply(amount_squared)
			.add(
				v2.multiply(3.0).sub(v1).add(v3.multiply(3.0)).add(v4)
			)
			.multiply(0.5)
		)
	)
	*/
	/*
	return (
		(
			v2.multiply(2.0)
			.add(v3.sub(v1).multiply(amount))
			.add(
				// v1.multiply(2.0).sub(v2.multiply(5.0)).add(v3.multiply(4.0)).sub(v4).multiply(amount_squared)
				v1.multiply(2.0).sub(v2.multiply(5.0))
				.add(v3.multiply(4.0)).sub(v4).multiply(amount_squared)
				
				)
			.add(
				v2.multiply(3.0).sub(v1)
				.sub(v3.multiply(3.0))
				.sub(v4)
				.multiply(amount_cubed)
			)
			.multiply(0.5)
		)
	)
	*/
	return (
		(
			v2.multiply_(2.0)
			.add_(v3.sub_(v1))
			.multiply_(amount)
			.add_(
				v1.multiply_(2.0).sub_(v2.multiply_(5.0))
				.add_(v3.multiply_(4.0)).sub_(v4)
				)
			.multiply_(amount_squared)				
			.add_(
				v2.multiply_(3.0).sub_(v1)
				.sub_(v3.multiply_(3.0))
				.sub_(v4)
				.multiply_(amount_cubed)
			)
			.multiply_(0.5)
			
		).multiply_(-1)
	)
	
}

pub fn create_catmull(control_points []Vector2) []Vector2 {
	mut output := []Vector2{}

	tolerance := f64(50.0)

	for j := 0; j < control_points.len - 1; j ++ {
		v1 := if j - 1 >= 0 { control_points[j-1] } else { control_points[j] }
		v2 := control_points[j]
		v3 := if j + 1 < control_points.len { control_points[j + 1] } else { v2.add_(v2).sub_(v1) }
		v4 := if j + 2 < control_points.len { control_points[j + 1] } else { v3.add_(v3).sub_(v2) }

		for k := 0; k < tolerance; k++ {
			output << catmul_rom(v1, v2, v3, v4, k / tolerance)
		}
	}

	return output
}