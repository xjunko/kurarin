module sprite

import library.gg
import framework.math.vector
import core.osu.skin

pub struct NumberSprite {
	Sprite
pub mut:
	fonts map[string]gg.Image
	text  string
}

pub fn (mut number NumberSprite) draw(arg CommonSpriteArgument) {
	number.draw_number(number.text, number.position, number.origin, arg)
}

// draw_number is its own thing so we can use it as a generic number drawer
pub fn (mut number NumberSprite) draw_number(text string, position vector.Vector2, origin vector.Origin, arg CommonSpriteArgument) {
	if number.is_drawable_at(arg.time) || number.always_visible {
		mut base_position := position.sub(origin.multiply(
			x: number.size.x * text.len
			y: number.size.y
		).scale(arg.scale))

		size := number.size.scale(arg.camera.scale * arg.scale)

		for character in text {
			character_image := &unsafe { number.fonts[character.str_escaped()] }
			character_position := arg.camera.translate(base_position)

			arg.ctx.draw_image_with_config(
				img: character_image
				img_id: character_image.id
				img_rect: gg.Rect{
					x: f32(character_position.x)
					y: f32(character_position.y)
					width: f32(size.x)
					height: f32(size.y)
				}
				color: number.color
				additive: number.additive
			)

			base_position.x += number.size.x * (arg.scale)
		}
	}
}

pub fn make_number_sprite(number int, prefix string) &NumberSprite {
	mut sprite := &NumberSprite{}
	sprite.text = number.str()

	// / TODO: maybe cache the imgs somewhere?
	for i in 0 .. 10 {
		sprite.fonts[i.str()] = skin.get_texture('${prefix}-${i}')
	}

	// HACK: we only need one texture for this to work
	sprite.textures << sprite.fonts['0']

	// size
	sprite.reset_size_based_on_texture(
		size: vector.Vector2{sprite.fonts['0'].width, sprite.fonts['0'].height}
	)

	return sprite
}

// Use make_number_font to use NumberSprite as a generic number drawer
pub fn make_number_font(prefix string) &NumberSprite {
	mut sprite := make_number_sprite(0, prefix)
	sprite.always_visible = true

	return sprite
}
