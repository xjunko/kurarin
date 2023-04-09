module easing

// Storyboard type beat shit
pub enum Easing {
	linear
	ease_out
	ease_in
	quad_in
	quad_out
	quad_in_out
	cubic_in
	cubic_out
	cubic_in_out
	quart_in
	quart_out
	quart_in_out
	quint_in
	quint_out
	quint_in_out
	sine_in
	sine_out
	sine_in_out
	expo_in
	expo_out
	expo_in_out
	circ_in
	circ_out
	circ_in_out
	elastic_in
	elastic_out
	elastic_half_out
	elasic_quart_out
	elastic_in_out
	back_in
	back_out
	back_in_out
	bounce_in
	bounce_out
	bounce_in_out
}

pub fn get_easing_from_enum(e Easing) EasingFunction {
	// return match e {
	// 	.linear { linear }
	// 	.quad_in { quad_in }
	// 	.quad_out { quad_out }
	// 	.quad_in_out { quad_in_out }
	// 	else { quad_out }
	// }

	// This is fucked
	return match int(e) {
		int(Easing.linear) { linear }
		int(Easing.quad_in) { quad_in }
		int(Easing.quad_out) { quad_out }
		int(Easing.quad_in_out) { quad_in_out }
		int(Easing.quart_in) { quart_in }
		int(Easing.quart_out) { quart_out }
		int(Easing.quart_in_out) { quart_in_out }
		int(Easing.quint_in) { quint_in }
		int(Easing.quint_out) { quint_out }
		int(Easing.quint_in_out) { quint_in_out }
		int(Easing.sine_in) { sine_in }
		int(Easing.sine_out) { sine_out }
		int(Easing.sine_in_out) { sine_in_out }
		int(Easing.elastic_in) { elastic_in }
		int(Easing.elastic_out) { elastic_out }
		int(Easing.elastic_in_out) { elastic_in_out }
		else { quad_out }
	}

	// V cant compile the one below for some reason
	// return match e {
	// 	.linear { linear }
	// 	.quad_in { quad_in }
	// 	.quad_out { quad_out }
	// 	.quad_in_out { quad_in_out }
	// 	// .quart_in { quart_in }
	// 	// .quart_out { quart_out }
	// 	// .quart_in_out { quart_in_out }
	// 	// .quint_in { quint_in }
	// 	// .quint_out { quint_out }
	// 	// .quint_in_out { quint_in_out }
	// 	// .sine_in { sine_in }
	// 	// .sine_out { sine_out }
	// 	// .sine_in_out { sine_in_out }
	// 	else { quad_out }
	// }
}
