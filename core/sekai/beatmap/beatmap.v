module beatmap

import object

import gx
import library.gg
import sokol.sgl

import framework.math.time
import framework.math.vector
import framework.graphic.sprite

pub struct Beatmap {
	mut:
		ctx &gg.Context = unsafe { 0 }
		last_update_time f64

	pub mut:
		internal &InternalBeatmap = unsafe { 0 }

		objects []&object.INoteObject
		sprites &sprite.Manager = sprite.make_manager()
}

pub fn (mut beatmap Beatmap) bind_context(mut ctx &gg.Context) {
	beatmap.ctx = unsafe { ctx }
}

pub fn (mut beatmap Beatmap) reset() {
	beatmap.ensure_background_loaded()
	beatmap.load_objects()
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

pub fn (mut beatmap Beatmap) load_objects() {
	for i := 0; i < beatmap.internal.notes.len; i++ {
		mut note_sprite := &object.NoteObjectSprite{
			object: beatmap.internal.notes[i]
		}

		note_sprite.initialize(
			beatmap.internal.notes[i].is_flick,
			beatmap.internal.notes[i].is_critical,
			0 // Always 0, this is a note, not flick
		)

		beatmap.objects << note_sprite
	}
}

pub fn (mut beatmap Beatmap) update(time f64) {
	beatmap.sprites.update(time)

	for i := 0; i < beatmap.objects.len; i++ {
		if time >= beatmap.objects[i].time.start - 1000 && time <= beatmap.objects[i].time.end + 1000 {
			beatmap.objects[i].update(time)
		}
	}

	beatmap.last_update_time = time
}

pub fn (mut beatmap Beatmap) draw(arg sprite.CommonSpriteArgument) {
	beatmap.sprites.draw(arg)

	beatmap.switch_to_sekai_camera(arg)
	for i := 0; i < beatmap.objects.len; i++ {
		if beatmap.last_update_time >= beatmap.objects[i].time.start - 1000 && beatmap.last_update_time <= beatmap.objects[i].time.end + 1000 {
			beatmap.objects[i].draw(arg)
		}
	}
	beatmap.switch_to_normal_camera()
}

// funny
pub fn (mut beatmap Beatmap) switch_to_sekai_camera(arg sprite.CommonSpriteArgument) {
	// Perspective
    sgl.defaults()
    sgl.load_pipeline(arg.ctx.timage_pip)

    fov := f32(50.0)

    sgl.matrix_mode_projection()
    sgl.perspective(sgl.rad(fov), 1.0, 0.0, 1000.0)

    sgl.matrix_mode_modelview()
    sgl.translate(0.0, 0.0, -13.0)

    sgl.rotate(sgl.rad(-60), 1.0, 0.0, 0.0)
    sgl.rotate(sgl.rad(0), 0.0, 1.0, 0.0)

    arg.ctx.draw_rect_filled(-0.5 * 6.5, -7.3, 0.5 * 13, 1, gx.red)
    arg.ctx.draw_line(0, 0, 0, 100, gx.green)
}

pub fn (mut beatmap Beatmap) switch_to_normal_camera() {
	// Reset camera
    sgl.defaults()
    sgl.matrix_mode_projection()
    sgl.ortho(0.0, 1280, 720, 0.0, -1.0, 1.0)
}