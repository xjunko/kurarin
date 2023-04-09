module object

import math
import framework.graphic.sprite
import framework.math.time
import core.osu.skin
import core.osu.audio
import core.osu.beatmap.difficulty

pub struct Spinner {
	HitObject
pub mut:
	sprites []sprite.ISprite

	spinner_circle   &sprite.Sprite = &sprite.Sprite{}
	spinner_approach &sprite.Sprite = &sprite.Sprite{}

	last_time f64
	done      bool
}

pub fn (mut spinner Spinner) draw(arg sprite.CommonSpriteArgument) {
	for mut sprite in spinner.sprites {
		sprite.draw(arg)
	}
}

pub fn (mut spinner Spinner) update(update_time f64) bool {
	spinner.last_time = update_time

	for mut sprite in spinner.sprites {
		sprite.update(update_time)
	}

	// Play hitsound when finished
	if update_time >= spinner.get_end_time() && !spinner.done {
		spinner.done = true
		// TODO: proper spinner hitsound
		audio.play_sample(spinner.hitsound.sample_set, spinner.hitsound.addition_set,
			0, spinner.hitsound.custom_index, 1.0)
	}

	return true
}

pub fn (mut spinner Spinner) set_difficulty(diff difficulty.Difficulty) {
	spinner.diff = diff

	// Time
	start_time := spinner.get_start_time() - spinner.diff.preempt
	end_time := spinner.get_start_time()
	duration := spinner.data[5].split(':')[0].f64() - end_time
	spinner.time.end += duration

	// Texture
	spinner.spinner_circle.textures << skin.get_texture('spinner-circle')
	spinner.spinner_approach.textures << skin.get_texture('spinner-approachcircle')

	// Add to sprites
	spinner.sprites << spinner.spinner_circle
	spinner.sprites << spinner.spinner_approach

	// Animation
	for mut t in spinner.sprites {
		t.add_transform(
			typ: .move
			time: time.Time{start_time, start_time}
			before: [
				spinner.position.x,
				spinner.position.y,
			]
		)
		t.add_transform(
			typ: .fade
			time: time.Time{start_time, end_time}
			before: [
				0.0,
			]
			after: [255.5]
		)
		t.add_transform(
			typ: .fade
			time: time.Time{spinner.time.end, spinner.time.end + difficulty.hit_fade_out}
			before: [255.0]
			after: [0.0]
		)
		t.add_transform(
			typ: .scale_factor
			time: time.Time{start_time, start_time}
			before: [
				0.75,
			]
		)
		t.add_transform(
			typ: .angle
			time: time.Time{start_time, spinner.time.end}
			before: [
				0.0,
			]
			after: [math.pi * 2.0]
		)

		t.reset_size_based_on_texture()
		t.reset_attributes_based_on_transforms()
	}

	spinner.spinner_approach.add_transform(
		typ: .scale_factor
		time: time.Time{start_time, spinner.time.end}
		before: [2.0 * 0.75]
		after: [0.0]
	)
	spinner.spinner_approach.reset_attributes_based_on_transforms()
}

//
pub fn make_spinner(items []string) &Spinner {
	mut hspinner := &Spinner{
		HitObject: common_parse(items, 6)
	}

	return hspinner
}
