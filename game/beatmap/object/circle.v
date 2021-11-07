module object

import math
import lib.gg

import framework.audio
import framework.math.time as time2
import framework.math.easing
import framework.math.vector
import framework.graphic.sprite


import game.logic
import game.animation
import game.math.timing
import game.math.difficulty

const (
	sample_name = ["normal", "soft", "drum"]
)


pub struct HitObject {
	pub mut:
		id              int
		ctx             &gg.Context = voidptr(0)
		position        vector.Vector2
		end_position    vector.Vector2
		time            time2.Time
		sprites         []sprite.IDrawable
		stacking        int

		logic           &logic.HitCircle
		diff            difficulty.Difficulty
		timing          timing.TimingPoint

		hitcircle        &sprite.Sprite = &sprite.Sprite{}
		hitcircleoverlay &sprite.Sprite = &sprite.Sprite{}
		approachcircle   &sprite.Sprite = &sprite.Sprite{}
		hitanimation     &sprite.Sprite = &sprite.Sprite{}
		combo_sprite     &sprite.Sprite = &sprite.Sprite{}

		hitsound          string = 'drum-hitnormal'
		color             []f64
		is_hidden 		  bool
		is_spinner        bool
		is_slider 		  bool
		is_new_combo      bool
		prev_object_logic &logic.HitCircle = voidptr(0)
		combo_index       int
		data              []string
		ratiod_scale      vector.Vector2
}

pub fn (mut hitobject HitObject) draw(ctx &gg.Context, time f64) {
	for mut sprite in hitobject.sprites {
		sprite.draw_and_update(ctx: ctx, time: time)
	}
	hitobject.logic.draw_debug_hitbox(ctx, time)
}

pub fn (mut hitobject HitObject) pre_init() {
	hitobject.is_new_combo = (hitobject.data[3].int() & 4) > 0

	// Hitsound
	hitobject_sample := hitobject.data[4].int()
	timing := hitobject.timing.get_point_at(hitobject.time.start)
	prefix := sample_name[int(timing.sampleset)]

	if (hitobject_sample & 1) > 0 || hitobject_sample == 0 {
		hitobject.hitsound = '${prefix}-hitnormal'
	}

	if (hitobject_sample & 2) > 0 {
		hitobject.hitsound = '${prefix}-hitwhistle'
	}

	if (hitobject_sample & 4) > 0 {
		hitobject.hitsound = '${prefix}-hitfinish'
	}

	if (hitobject_sample & 8) > 0 {
		hitobject.hitsound = '${prefix}-hitclap'
	}	
}

pub fn (mut hitobject HitObject) initialize_object(mut ctx &gg.Context, last_object IHitObject) {
	hitobject.ctx = ctx
	hitobject.prev_object_logic = last_object.logic
	hitobject.end_position = hitobject.position // unless its a slider

	// HitCircle
	hitobject.hitcircle = &sprite.Sprite{textures: [ctx.get_texture_from_skin('hitcircle')]}
	hitobject.hitcircleoverlay = &sprite.Sprite{textures: [ctx.get_texture_from_skin('hitcircleoverlay')]}

	// combo
	hitobject.combo_sprite = &sprite.Sprite{
		typ: .text, 
		text: hitobject.combo_index.str()
	}

	// MAN
	mut clickable := []&sprite.Sprite{}
	clickable << hitobject.hitcircle
	clickable << hitobject.hitcircleoverlay
	clickable << hitobject.combo_sprite

	diff := hitobject.diff
	// size_ratio := ((diff.circleradius) * 1.05 * 2 / 128) // this is about the same value as the size_ratio below but idk man
	mut size_ratio := (54.4 - 4.48 * diff.cs) * 1.05 * 2 / 128
	// size_ratio *= resolution.global.playfield_scale
	
	size := vector.Vector2{
		hitobject.hitcircle.image().width * size_ratio,
		hitobject.hitcircle.image().height * size_ratio
	}

	start_time := hitobject.time.start - diff.preempt
	end_time := hitobject.time.start	

	// combo colour
	hitobject.hitcircle.add_transform(typ: .color, time: time2.Time{start_time, start_time}, before: hitobject.color)
	hitobject.hitcircleoverlay.add_transform(typ: .color, time: time2.Time{start_time, start_time}, before: hitobject.color)

	hitobject.ratiod_scale = size
	for mut sprite in clickable {
		sprite.add_transform(typ: .move, easing: easing.linear, time: time2.Time{start_time, start_time}, before: [hitobject.position.x, hitobject.position.y])
		sprite.add_transform(typ: .scale_factor, easing: easing.linear, time: time2.Time{start_time, start_time}, before: [f64(1)])

		if hitobject.is_hidden {
			sprite.add_transform(typ: .fade, easing: easing.linear, time: time2.Time{start_time, start_time + diff.preempt * 0.4}, before: [f64(0)], after: [f64(255)])
			sprite.add_transform(typ: .fade, easing: easing.linear, time: time2.Time{start_time + diff.preempt * 0.4, start_time + diff.preempt * 0.7}, before: [f64(255)], after: [f64(0)])
		}
		else {
			sprite.add_transform(typ: .fade, easing: easing.linear, time: time2.Time{start_time, start_time + difficulty.hit_fade_in}, before: [f64(0)], after: [f64(255)])
			sprite.add_transform(typ: .fade, easing: easing.linear, time: time2.Time{end_time + diff.hit100, end_time + diff.hit50}, before: [f64(255)], after: [f64(0)])
			// println("${start_time + difficulty.hit_fade_in} ${end_time} | ${end_time + diff.hit100} ${end_time + diff.hit50}")
		}

		sprite.after_add_transform_reset()
		sprite.change_size(size: size)
	}

	mut combo_sprite_size := size.copy()
	combo_sprite_size.scale(0.7)
	hitobject.combo_sprite.change_size(size: combo_sprite_size)

	if !hitobject.is_hidden || hitobject.id == 0 {
		// fake ass approach rate
		hitobject.approachcircle = &sprite.Sprite{textures: [ctx.get_texture_from_skin('approachcircle')]}
		hitobject.approachcircle.add_transform(typ: .move, easing: easing.linear, time: time2.Time{start_time, start_time}, before: [hitobject.position.x, hitobject.position.y])
		hitobject.approachcircle.add_transform(typ: .fade, easing: easing.linear, time: time2.Time{start_time, math.min(end_time, end_time - diff.preempt + difficulty.hit_fade_in * 2)}, before: [f64(0)], after: [f64(229)])
		hitobject.approachcircle.add_transform(typ: .fade, easing: easing.linear, time: time2.Time{end_time, end_time}, before: [f64(0)], after: [f64(0)])
		hitobject.approachcircle.add_transform(typ: .scale_factor, easing: easing.linear, time: time2.Time{start_time, end_time}, before: [f64(4)], after: [f64(0.9)])		

		hitobject.approachcircle.add_transform(typ: .color, time: time2.Time{start_time, start_time}, before: hitobject.color)
		
		hitobject.approachcircle.after_add_transform_reset()
		hitobject.approachcircle.change_size(size: size)
	}

	hitobject.hitanimation = animation.make_hit_animation(.hmiss, hitobject.position, end_time)
	hitobject.hitanimation.change_size(size: size, keep_ratio: true)

	hitobject.sprites = [
		hitobject.hitcircle,
		hitobject.hitcircleoverlay,
		hitobject.approachcircle,
		hitobject.hitanimation,
		hitobject.combo_sprite
	]
}

pub fn (mut hitobject HitObject) check_if_mouse_clicked_on_hitobject(x f64, y f64, time f64, osu_space bool) {
	// force last object to be hit-ed
	/* if !hitobject.prev_object_logic.is_hittable(time) && !hitobject.prev_object_logic.clicked && !hitobject.logic.clicked {
		hitobject.prev_object_logic.clicked = true
	}*/
	

	if hitobject.logic.is_cursor_on_hitcircle(x, y, osu_space) && hitobject.logic.is_hittable(time) && !hitobject.logic.clicked {
		mut audio_ptr := audio.global
		audio_ptr.add_audio_and_play_blocking(path: 'assets/skins/default/${hitobject.hitsound}.wav') // dont play audio for now
		hitobject.logic.clicked = true
		// resets
		hitobject.hitcircle.reset_transforms()
		hitobject.hitcircleoverlay.reset_transforms()
		hitobject.combo_sprite.reset_transforms()
		
		start_time := time
		//
		hitobject.approachcircle.reset_transforms()
		hitobject.approachcircle.add_transform(typ: .fade, easing: easing.linear, time: time2.Time{start_time, start_time}, before: [f64(0)])

		end_scale := f64(1.4)
		// TODO: skin version < 2 = end_scale := 1.8
		animation.modify_hit_animation(mut hitobject.hitanimation, .h300, start_time)

		if !hitobject.is_hidden {
			end_time := start_time + difficulty.hit_fade_out
			// scale
			hitobject.hitcircle.add_transform(typ: .scale_factor, easing: easing.quad_out, time: time2.Time{start_time, end_time}, before: [f64(1)], after: [end_scale])
			hitobject.hitcircleoverlay.add_transform(typ: .scale_factor, easing: easing.quad_out, time: time2.Time{start_time, end_time}, before: [f64(1)], after: [end_scale])

			// fade
			hitobject.hitcircle.add_transform(typ: .fade, easing: easing.linear, time: time2.Time{start_time, end_time}, before: [f64(255)], after: [f64(0)])
			hitobject.hitcircleoverlay.add_transform(typ: .fade, easing: easing.linear, time: time2.Time{start_time, end_time}, before: [f64(255)], after: [f64(0)])
			hitobject.combo_sprite.add_transform(typ: .fade, easing: easing.linear, time: time2.Time{start_time, end_time}, before: [f64(255)], after: [f64(0)])
		}
		else {
			end_time := start_time + 60
			hitobject.hitcircle.add_transform(typ: .fade, easing: easing.quad_out, time: time2.Time{start_time, end_time}, before: [f64(hitobject.hitcircle.color.a)], after: [f64(0)])
			hitobject.hitcircleoverlay.add_transform(typ: .fade, easing: easing.quad_out, time: time2.Time{start_time, end_time}, before: [f64(hitobject.hitcircleoverlay.color.a)], after: [f64(0)])
			hitobject.combo_sprite.add_transform(typ: .fade, easing: easing.quad_out, time: time2.Time{start_time, end_time}, before: [f64(hitobject.hitcircleoverlay.color.a)], after: [f64(0)])
		}
	} 
	
	if !hitobject.logic.clicked && hitobject.logic.is_hittable(time) && hitobject.logic.is_cursor_on_hitcircle(x, y, osu_space) {

		hitobject.hitcircle.reset_transforms()
		hitobject.hitcircleoverlay.reset_transforms()
		hitobject.combo_sprite.reset_transforms()

		start_time := time

		for i in 0 .. 3 {
			hitobject.hitcircle.add_transform(typ: .move, easing: easing.quad_out, time: time2.Time{start_time + (100*i), start_time + (300*i)}, before: [hitobject.position.x, hitobject.position.y], after: [hitobject.position.x + [30, -30][int(i % 2 == 0)], hitobject.position.y])
			hitobject.hitcircleoverlay.add_transform(typ: .move, easing: easing.quad_out, time: time2.Time{start_time + (100*i), start_time + (300*i)}, before: [hitobject.position.x, hitobject.position.y], after: [hitobject.position.x + [30, -30][int(i % 2 == 0)], hitobject.position.y])
			hitobject.combo_sprite.add_transform(typ: .move, easing: easing.quad_out, time: time2.Time{start_time + (100*i), start_time + (300*i)}, before: [hitobject.position.x, hitobject.position.y], after: [hitobject.position.x + [30, -30][int(i % 2 == 0)], hitobject.position.y])
		}

		hitobject.logic.clicked = true
	}
}

// Common Functions
/*
pub fn (mut hitobject HitObject) sort_sprites_based_on_z_layer() {
	hitobject.sprites.sort(a.z < b.z)
}
*/