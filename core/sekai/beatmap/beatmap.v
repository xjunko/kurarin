module beatmap

import object

import library.gg

import framework.math.time
import framework.math.vector
import framework.graphic.sprite

pub struct Beatmap {
	mut:
		ctx &gg.Context = unsafe { 0 }

	pub mut:
		objects []object.INoteObject
		sprites &sprite.Manager = sprite.make_manager()
}

pub fn (mut beatmap Beatmap) bind_context(mut ctx &gg.Context) {
	beatmap.ctx = unsafe { ctx }
}

pub fn (mut beatmap Beatmap) ensure_background_loaded() {
    // Background
    for i, filename in ["default", "field"] {
        mut sprite := &sprite.Sprite{always_visible: true}
        sprite.textures << beatmap.ctx.create_image("assets/psekai/textures/${filename}.png")


        sprite.add_transform(typ: .move, time: time.Time{0.0, 0.0}, before: [1280.0 / 2.0, 720.0 / 2.0 + (f64(i) * 70.0)])

        if i == 1 {
            sprite.add_transform(typ: .scale_factor, time: time.Time{0.0, 0.0}, before: [1.18])
        }

        sprite.reset_size_based_on_texture(fit_size: true, source: vector.Vector2{1280, 720})        
        sprite.reset_attributes_based_on_transforms()

        beatmap.sprites.add(mut sprite)
    }
}

pub fn (mut beatmap Beatmap) update(time f64) {
	beatmap.sprites.update(time)
}

pub fn (mut beatmap Beatmap) draw(arg sprite.CommonSpriteArgument) {
	beatmap.sprites.draw(arg)
}