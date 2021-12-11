module sprite

import lib.gg
import gx
import math

import framework.transform
import framework.math.time
import framework.math.vector
import framework.math.easing

// had to do this since interface doesnt support embedded struct :ihatemylife:
pub enum SpriteType {
	image
	text
}


pub struct Sprite {
	pub mut:
		typ        SpriteType = SpriteType.image
		time 	   &time.Time = &time.Time{}
		position   &vector.Vector2 = &vector.Vector2{}
		origin     vector.Vector2 = vector.centre
		size       vector.Vector2
		base_size  vector.Vector2
		color      gx.Color = gx.white
		angle      f64
		z          int

		textures   []gg.Image
		texture_i  int

		// text
		text	string

		// attr
		special    	   bool
		always_visible bool
		skip_offset    bool

		// transform
		transforms []transform.Transform
		transforms_i int // mmmmmm idk
}

pub fn (s Sprite) image() &gg.Image {
	if s.texture_i < s.textures.len {
		return &s.textures[s.texture_i]
	}

	return &gg.Image{}
}

// Event FNs
// bullshit
pub fn (mut s Sprite) apply_transform(t transform.Transform, time f64) {
	match t.typ {
		.fade {
			s.color.a = byte(t.as_one(time))
		}

		.angle {
			s.angle = (t.as_one(time) * 180 / math.pi) * -1.0 // this looks retarded why not just use 360 isntead of this
		}

		.scale {
			// Bruh
			val := t.as_vector(time)
			s.size.x = s.base_size.x * val.x
			s.size.y = s.base_size.y * val.y
		}

		.move_x {
			val := t.as_one(time)
			s.position.x = val
		}

		.move_y {
			val := t.as_one(time)
			s.position.y = val
		}

		.move {
			val := t.as_vector(time)
			s.position.x = val.x
			s.position.y = val.y
		}

		.scale_factor {
			val := t.as_one(time)
			s.size.x = s.base_size.x * val
			s.size.y = s.base_size.y * val
		}

		.color {
			val := t.as_three(time)
			s.color.r = byte(val[0])
			s.color.g = byte(val[1])
			s.color.b = byte(val[2])
		}

		
	}
}

pub struct AddTransformArgument {
	typ 	transform.TransformType
	easing 	easing.EasingFunction = easing.linear // this is fucking repetitive to write
	time    time.Time
	before  []f64
	after   []f64
}

pub fn (mut s Sprite) add_transform(arg AddTransformArgument) {
	mut transform := transform.Transform{
		typ: arg.typ,
		easing: arg.easing,
		time: arg.time,
		before: arg.before,
		after: arg.after
	}
	transform.ensure_safe()
	s.transforms << transform

	// s.reset_time_based_on_transforms() // what if
}

pub fn (mut s Sprite) update(time f64) {
	for transform in s.transforms {
		if time >= transform.time.start && time <= transform.time.end {
			s.apply_transform(transform, time)
		}
	}
}



//
pub fn (mut s Sprite) reset_transforms() {
	s.transforms = []transform.Transform{}
}

pub fn (mut s Sprite) after_add_transform_reset() {
	s.reset_time_based_on_transforms()
	s.reset_image_size()
	s.reset_attributes_based_on_transforms()
}

pub fn (mut s Sprite) reset_time_based_on_transforms() {
	// lol
	s.transforms.sort(a.time.start < b.time.start)
	s.time.start = s.transforms[0].time.start
	s.transforms.sort(a.time.end > b.time.end)
	s.time.end = s.transforms[0].time.end

	// sort normally
	s.transforms.sort(a.time.start < b.time.start)
}

pub fn (mut s Sprite) reset_attributes_based_on_transforms() {
	mut applied := []transform.TransformType{}

	for transform in s.transforms {
		if transform.typ !in applied {
			s.apply_transform(transform, transform.time.start)
			applied << transform.typ
			// println('applying ${transform.typ}, time: ${transform.time.start}, value: ${transform.before} - ${transform.after}, duration: ${transform.time.duration()}')
		}
	}
}

pub fn (mut s Sprite) reset_image_size() {
	if s.textures.len > 0 {
		s.change_size(size: vector.Vector2{s.image().width, s.image().height})
	} else {
		// No scale factor??? just use 1x1 i guess
		s.change_size(size: vector.Vector2{1, 1})
	}
}

pub struct ChangeSizeArg {
	size vector.Vector2
	keep_ratio bool
}

pub fn (mut s Sprite) change_size(arg ChangeSizeArg) {
	if arg.keep_ratio {
		mut height := s.base_size.y

		// use image hieght if base size is not there
		if s.base_size.y == 0 {
			height = f64(s.image().height)
		}
	
		ratio := arg.size.y / height
		s.base_size.x = s.base_size.x * ratio
		s.base_size.y = s.base_size.y * ratio
		s.size.x = s.size.x * ratio
		s.size.y = s.size.y * ratio
		return
	}

	s.base_size.x = arg.size.x
	s.base_size.y = arg.size.y
	s.size.x = arg.size.x
	s.size.y = arg.size.y
}

pub fn (mut s Sprite) remove_all_transform_with_type(typ transform.TransformType) {
	s.transforms = s.transforms.filter(it.typ != typ)
}

//
pub fn (s Sprite) check_if_drawable(time f64) bool {
	/*
	for transform in s.transforms {
		if time >= transform.time.start && time <= transform.time.end {
			return true
		}
	*/
	if time >= s.time.start && time <= s.time.end && s.color.a > 0.0 {
		return true
	}

	return false
}





pub fn (s Sprite) draw(cfg DrawConfig) {
	if !s.check_if_drawable(cfg.time) && !s.always_visible { return }

	mut img := s.image()

	// reference
	// x := f32(((s.position.x * cfg.scale) -  x_pos.x) + cfg.offset.x * cfg.scale)
	// y := f32(((s.position.y * cfg.scale) - y_pos.y) + cfg.offset.y * cfg.scale)
	// width := f32(s.size.x * cfg.scale)
	// height := f32(s.size.y * cfg.scale)
	
	// use vector methods
	size := s.size.scale(cfg.scale)
	origin := size.multiply(s.origin)

	mut position := s.position.scale(cfg.scale).sub(origin).add(cfg.offset.scale(cfg.scale))

	if s.skip_offset {
		// real
		// position = s.position.sub_(s.size.scale_origin_(s.origin))
		//cfg.ctx.draw_rect(f32(position.x), f32(position.y), 32, 32, gx.red)
		// cved
		//mut position_cv := s.position.scale_(cfg.scale).sub_(origin).add_(cfg.offset.scale_(cfg.scale))
		//cfg.ctx.draw_rect(f32(position_cv.x), f32(position_cv.y), 32, 32, gx.yellow)
	}

	match s.typ {
		.image {
			cfg.ctx.draw_image_with_config(
				img: img,
				img_id: img.id,
				img_rect: gg.Rect{
					x: f32(position.x),
					y: f32(position.y),
					width: f32(size.x),
					height: f32(size.y)
				}
				color: s.color,
				rotate: f32(s.angle),
				z: s.z
			)
		}

		.text {
			cfg.ctx.draw_text(
				int(position.x + (s.size.x * cfg.scale) / 2), 
				int(position.y), 
				s.text, 
				gx.TextCfg{
					color: s.color,
					size: int(size.x),
					align: .center
				}
			)
		}
	}
}	

pub fn (mut s Sprite) draw_and_update(cfg DrawConfig) {
	s.update(cfg.time)
	s.draw(cfg)
}