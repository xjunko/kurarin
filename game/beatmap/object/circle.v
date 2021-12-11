module object

import math
import lib.gg

import framework.audio
import framework.math.time as time2
import framework.math.easing
import framework.math.vector
import framework.graphic.sprite


import game.animation
import game.math.timing
import game.math.difficulty

pub struct HitObject {
	pub mut:
		id              int
		ctx             &gg.Context = voidptr(0)
		position        vector.Vector2
		end_position    vector.Vector2
		time            time2.Time
		sprites         []sprite.IDrawable
		stacking        int

		diff            difficulty.Difficulty
		timing          timing.TimingPoint

		hitcircle        &sprite.Sprite = &sprite.Sprite{}
		hitcircleoverlay &sprite.Sprite = &sprite.Sprite{}
		approachcircle   &sprite.Sprite = &sprite.Sprite{}
		hitanimation     &sprite.Sprite = &sprite.Sprite{}
		combo_sprite     &sprite.ComboSprite = &sprite.ComboSprite{}

		hitsound          string = 'drum-hitnormal'
		color             []f64
		is_hidden 		  bool
		is_spinner        bool
		is_slider 		  bool
		is_new_combo      bool
		combo_index       int
		data              []string
		ratiod_scale      vector.Vector2

		// TODO: put this somewhere else
		sample 	   int
		sample_set int
}

pub fn (mut hitobject HitObject) draw(ctx &gg.Context, time f64) {
	// for mut sprite in hitobject.sprites {
	// 	sprite.draw_and_update(ctx: ctx, time: time)
	// }
}

pub fn (mut hitobject HitObject) pre_init() {
	if hitobject.data.len <= 4 { return } // ?????????
	hitobject.is_new_combo = (hitobject.data[3].int() & 4) > 0

	// Hitsound
	hitobject.sample = hitobject.data[4].int()
	timing := hitobject.timing.get_point_at(hitobject.time.start)

	if hitobject.data.len > 5 && (hitobject.data[3].int() & 1) > 0 {
		hitobject.sample_set = hitobject.data[5].split(":")[0].int()
	} else {
		// Use timing sampleset
		hitobject.sample_set = int(timing.sampleset)
	}

	// TODO: unfuck sampleset
	if hitobject.sample_set == 0 {
		hitobject.sample_set = 1 
	}
}

pub fn (mut hitobject HitObject) play_hitsound() {
	mut audio_ptr := audio.global
	audio_ptr.play_osu_sample(hitobject.sample, hitobject.sample_set)
}

pub fn (mut hitobject HitObject) initialize_object(mut ctx &gg.Context, last_object IHitObject) {
	hitobject.ctx = ctx
	hitobject.end_position = hitobject.position // unless its a slider

	// HitCircle
	hitobject.hitcircle = &sprite.Sprite{textures: [ctx.get_texture_from_skin('hitcircle')]}
	hitobject.hitcircleoverlay = &sprite.Sprite{textures: [ctx.get_texture_from_skin('hitcircleoverlay')]}

	// combo
	hitobject.combo_sprite.Sprite.textures = ctx.get_texture_expecting_animation_from_skin("default")
	hitobject.combo_sprite.number = hitobject.combo_index

	// MAN
	mut clickable := []&sprite.Sprite{}
	clickable << hitobject.hitcircle
	clickable << hitobject.hitcircleoverlay
	clickable << &hitobject.combo_sprite.Sprite

	diff := hitobject.diff
	size_ratio := ((diff.circleradius) * 1.05 * 2 / 128)
	
	size := vector.Vector2{
		hitobject.hitcircle.image().width * size_ratio,
		hitobject.hitcircle.image().height * size_ratio
	}

	start_time := hitobject.time.start - diff.preempt
	end_time := hitobject.time.start	

	// combo colour
	hitobject.hitcircle.add_transform(typ: .color, time: time2.Time{start_time, start_time}, before: hitobject.color)
	// hitobject.hitcircleoverlay.add_transform(typ: .color, time: time2.Time{start_time, start_time}, before: hitobject.color) // HitCircleOverlay dont use combo colors

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


	hitobject.combo_sprite.pre_init()
	combo_sprite_size := hitobject.combo_sprite.size.clone().scale(size_ratio * 0.8)
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

	hitobject.hitanimation = &sprite.Sprite{}
	hitobject.hitanimation.position.x = hitobject.position.x
	hitobject.hitanimation.position.y = hitobject.position.y
	// hitobject.hitanimation.add_transform(typ: .move, time: time2.Time{hitobject.time.start, hitobject.time.start}, before: [hitobject.position.x, hitobject.position.y])
	// hitobject.hitanimation.change_size(size: size, keep_ratio: true)

	hitobject.sprites = [
		hitobject.hitcircle,
		hitobject.hitcircleoverlay,
		hitobject.approachcircle,
		hitobject.hitanimation,
	]
	hitobject.sprites << hitobject.combo_sprite // gcc failed if i mix them with normal sprites /shrug
}

pub fn (mut hitobject HitObject) arm(clicked bool, time f64) {
	if clicked {
		if !hitobject.is_slider { // Handled by slider
			hitobject.play_hitsound()
		}
		
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

		// animation
		relative := i64(math.abs(time - hitobject.time.start))
		mut hitanimationtype := animation.HitType.hmiss

		if relative < hitobject.diff.hit300 {
			hitanimationtype = .h300
		} else if relative < hitobject.diff.hit100 {
			hitanimationtype = .h100
		} else if relative < hitobject.diff.hit50 {
			hitanimationtype = .h50
		}
		animation.modify_hit_animation(mut hitobject.hitanimation, hitanimationtype, start_time)

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
	}  else {
		end_time := time + 60
		animation.modify_hit_animation(mut hitobject.hitanimation, animation.HitType.hmiss, time)
		hitobject.hitcircle.add_transform(typ: .fade, easing: easing.quad_out, time: time2.Time{time, end_time}, before: [f64(0)])
		hitobject.hitcircleoverlay.add_transform(typ: .fade, easing: easing.quad_out, time: time2.Time{time, end_time}, before: [f64(0)])
		hitobject.combo_sprite.add_transform(typ: .fade, easing: easing.quad_out, time: time2.Time{time, end_time}, before: [f64(0)])
	}

}

pub fn (mut hitobject HitObject) shake(time f64) {
	hitobject.hitcircle.reset_transforms()
	hitobject.hitcircleoverlay.reset_transforms()
	hitobject.combo_sprite.reset_transforms()

	start_time := time

	for i in 0 .. 3 {
		hitobject.hitcircle.add_transform(typ: .move, easing: easing.quad_out, time: time2.Time{start_time + (100*i), start_time + (300*i)}, before: [hitobject.position.x, hitobject.position.y], after: [hitobject.position.x + [30, -30][int(i % 2 == 0)], hitobject.position.y])
		hitobject.hitcircleoverlay.add_transform(typ: .move, easing: easing.quad_out, time: time2.Time{start_time + (100*i), start_time + (300*i)}, before: [hitobject.position.x, hitobject.position.y], after: [hitobject.position.x + [30, -30][int(i % 2 == 0)], hitobject.position.y])
		hitobject.combo_sprite.add_transform(typ: .move, easing: easing.quad_out, time: time2.Time{start_time + (100*i), start_time + (300*i)}, before: [hitobject.position.x, hitobject.position.y], after: [hitobject.position.x + [30, -30][int(i % 2 == 0)], hitobject.position.y])
	}
}

pub fn (mut hitobject HitObject) get_hit_object() &HitObject {
	unsafe {
		return &hitobject
	}
}
