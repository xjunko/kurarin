module animation

// import rand
import lib.gg

import framework.math.vector
import framework.math.time

import framework.graphic.sprite
import framework.math.easing

pub enum HitType {
	h300
	h100
	h50
	hmiss
}

pub fn (hittype HitType) get_filename() string {
	return match hittype {
		.h300 { 'hit300' }
		.h100 { 'hit100' }
		.h50  { 'hit50' }
		.hmiss { 'hit0' }
	}
}

pub fn ready_cache() {
	for t in [HitType.h300, HitType.h100, HitType.h50, HitType.hmiss] {
		gg.get_texture_from_skin(t.get_filename())
	}

	for t in ['cursor'] {
		gg.get_texture_from_skin(t)
	}
}

pub struct HitAnimation {
	pub mut:
		typ      HitType = .hmiss
		position vector.Vector2
		time     time.Time
}

pub fn make_hit_animation(typ HitType, position vector.Vector2, time_ f64) &sprite.Sprite {
	mut sprite := &sprite.Sprite{
		textures: [gg.get_texture_from_skin(typ.get_filename())]
		// angle: rand.f64_in_range(-10, 10)

	}
	if typ == .hmiss {
		sprite.add_transform(typ: .move, easing: easing.quad_out, time: time.Time{time_, time_ + 200}, before: [position.x, position.y], after: [position.x, position.y + 16])
	} else {
		sprite.remove_all_transform_with_type(.move)
		sprite.add_transform(typ: .move, easing: easing.linear, time: time.Time{time_, time_}, before: [position.x, position.y])
	}
	
	sprite.add_transform(typ: .fade, easing: easing.quad_out, time: time.Time{time_, time_ + 200}, before: [f64(0)], after: [f64(255)])
	sprite.add_transform(typ: .scale_factor, easing: easing.quad_out, time: time.Time{time_, time_ + 100}, before: [f64(1.4)], after: [f64(0.7)])
	sprite.add_transform(typ: .fade, easing: easing.quad_out, time: time.Time{time_ + 200, time_ + 400}, before: [f64(255)], after: [f64(0)])
	
	sprite.reset_time_based_on_transforms()
	sprite.reset_attributes_based_on_transforms()
	sprite.reset_image_size()
	// sprite.change_size(size: vector.Vector2{x: 64, y: 64}, keep_ratio: true)

	return sprite
}

pub fn modify_hit_animation(mut sprite sprite.Sprite, typ HitType, time_ f64) {
	sprite.textures = [gg.get_texture_from_skin(typ.get_filename())]


	sprite.remove_all_transform_with_type(.fade)
	sprite.remove_all_transform_with_type(.scale_factor)
	sprite.add_transform(typ: .fade, easing: easing.quad_out, time: time.Time{time_, time_ + 200}, before: [f64(0)], after: [f64(255)])
	sprite.add_transform(typ: .scale_factor, easing: easing.quad_out, time: time.Time{time_, time_ + 100}, before: [f64(1.4)], after: [f64(0.7)])
	sprite.add_transform(typ: .fade, easing: easing.quad_out, time: time.Time{time_ + 200, time_ + 400}, before: [f64(255)], after: [f64(0)])
	
	sprite.reset_time_based_on_transforms()
	sprite.reset_attributes_based_on_transforms()
	// sprite.reset_image_size() 
	// sprite.change_size(size: vector.Vector2{x: 64, y: 64}, keep_ratio: true)
}