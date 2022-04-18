module ruleset

pub enum HitResult {
	ignore
	slider_miss
	miss
	hit50
	hit100
	hit300
	slider_start
	slider_point
	slider_repeat
	slider_end
	spinner_spin
	spinner_points
	spinner_bonus
	mu_addition
	katu_addition
	geki_addition
}