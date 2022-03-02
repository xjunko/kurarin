module object

import library.gg

import framework.graphic.sprite
import framework.math.time

import game.x
import game.skin
import game.audio
import game.beatmap.difficulty

pub struct Spinner {
	HitObject

	pub mut:
		sprites []sprite.ISprite

		spinner_circle &sprite.Sprite = &sprite.Sprite{}
		spinner_approach &sprite.Sprite = &sprite.Sprite{}

		last_time f64
		done      bool
}


pub fn (mut spinner Spinner) draw(arg sprite.CommonSpriteArgument) {
	for mut sprite in spinner.sprites {
		if sprite.is_drawable_at(spinner.last_time) {
			pos := sprite.position.sub(sprite.origin.multiply(x: sprite.size.x, y: sprite.size.y))
			arg.ctx.draw_image_with_config(gg.DrawImageConfig{
					img: sprite.get_texture(),
					img_id: sprite.get_texture().id,
					img_rect: gg.Rect{
						x: f32(pos.x * x.resolution.playfield_scale + x.resolution.offset.x),
						y: f32(pos.y * x.resolution.playfield_scale + x.resolution.offset.y),
						width: f32(sprite.size.x * x.resolution.playfield_scale),
						height: f32(sprite.size.y * x.resolution.playfield_scale)
					},
					color: sprite.color
			})
		}
	}
}

pub fn (mut spinner Spinner) update(time f64) bool {
	spinner.last_time = time

	for mut sprite in spinner.sprites {
		sprite.update(time)
	}

	// Play hitsound when finished
	if time >= spinner.get_end_time() && !spinner.done {
		spinner.done = true
		audio.play_sample(
			spinner.hitsound.sample_set,
			spinner.hitsound.addition_set,
			0,
			spinner.hitsound.custom_index
		)
	}

	return true
}

pub fn (mut spinner Spinner) set_difficulty(diff difficulty.Difficulty) {
	spinner.diff = diff

	// Time
	start_time := spinner.get_start_time() - spinner.diff.preempt
	end_time := spinner.get_start_time()
	duration := spinner.data[5].split(":")[0].f64() - end_time
	spinner.time.end += duration

	// Texture
	spinner.spinner_circle.textures << skin.get_texture("spinner-circle")
	spinner.spinner_approach.textures << skin.get_texture("spinner-approachcircle")

	// Add to sprites
	spinner.sprites << spinner.spinner_circle
	spinner.sprites << spinner.spinner_approach

	// Animation
	for mut t in spinner.sprites {
		t.add_transform(typ: .move, time: time.Time{start_time, spinner.time.end}, before: [spinner.position.x, spinner.position.y])
		t.add_transform(typ: .fade, time: time.Time{start_time, end_time}, before: [0.0], after: [255.5])
		t.add_transform(typ: .fade, time: time.Time{spinner.time.end, spinner.time.end + difficulty.hit_fade_out}, before: [255.0], after: [0.0])
		t.add_transform(typ: .scale_factor, time: time.Time{start_time, start_time}, before: [0.75])
		

		t.reset_size_based_on_texture()
		t.reset_attributes_based_on_transforms()
	}

	spinner.spinner_approach.add_transform(typ: .scale_factor, time: time.Time{start_time, spinner.time.end}, before: [2.0 * 0.75], after: [0.0])
	spinner.spinner_approach.reset_attributes_based_on_transforms()
}


//
pub fn make_spinner(items []string) &Spinner {
	mut hspinner := &Spinner{
		HitObject: common_parse(items, 6)
	}

	return hspinner
}