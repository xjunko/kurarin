module object

import lib.gg

import game.logic
import game.math.difficulty

import framework.math.vector
import framework.math.time
import framework.graphic.sprite

pub interface IHitObject {
	mut:
	id  	 int
	ctx 	 &gg.Context
	position     vector.Vector2
	end_position vector.Vector2
	time     time.Time
	sprites  []sprite.IDrawable
	logic    &logic.HitCircle
	diff     difficulty.Difficulty
	stacking int

	combo_index int
	is_hidden bool
	is_spinner bool
	is_slider bool
	is_new_combo bool

	// FNs
	draw(ctx &gg.Context, time f64) 
	initialize_object(mut ctx &gg.Context, last_object IHitObject)
	check_if_mouse_clicked_on_hitobject(x f64, y f64, time f64, osu_space bool)
}

