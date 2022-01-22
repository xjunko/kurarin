module sprite

import library.gg
import framework.math.vector
import game.skin

pub struct NumberSprite {
	Sprite

	pub mut:
		number     int
		number_len int
		number_str string
		number_width f64
		number_img []&gg.Image
}

pub fn make_number_sprite(number int) &NumberSprite {
	mut sprite := &NumberSprite{}

	// / TODO: maybe cache the imgs somewhere?
	for i in 0 .. 10 {
		sprite.textures << skin.get_texture("default-${i}")
	}

	// TODO: tbh idk if i should do it like this cuz idw to calculate the same thing
	//       on every draw loop yknow so might as well do it once here
	sprite.number_str = number.str()
	sprite.number_len = sprite.number_str.len
	sprite.number_width = sprite.textures[0].width

	for digit in 0 .. sprite.number_len {
		sprite.number_img << &sprite.textures[sprite.number_str[digit].str_escaped().int()]
	}

	// size
	sprite.reset_size_based_on_texture(size: vector.Vector2{sprite.textures[0].width, sprite.textures[0].height})

	return sprite
}