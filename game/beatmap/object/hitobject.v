module object

import lib.gg

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
	get_hit_object() &HitObject
}

