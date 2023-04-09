module beatmap

import object
import math
import core.sekai.skin

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
		debug_view bool
		debug_view_sm f64

		internal &InternalBeatmap = unsafe { 0 }

		objects []&object.INoteObject
		objects_layer &sprite.Manager = sprite.make_manager()
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
        mut background_sprite := &sprite.Sprite{always_visible: true}
        background_sprite.textures << beatmap.ctx.create_image("assets/psekai/textures/${filename}.png")


        background_sprite.add_transform(typ: .move, time: time.Time{0.0, 0.0}, before: [1280.0 / 2.0, 720.0 / 2.0 + (f64(i) * 70.0)])

        if i == 1 {
            background_sprite.add_transform(typ: .scale_factor, time: time.Time{0.0, 0.0}, before: [1.18])
        }

        background_sprite.reset_size_based_on_texture(fit_size: true, source: vector.Vector2{1280, 720})        
        background_sprite.reset_attributes_based_on_transforms()

        beatmap.sprites.add(mut background_sprite)
    }
}

pub fn (mut beatmap Beatmap) load_objects() {
	// Note
	for i := 0; i < beatmap.internal.notes.len; i++ {
		mut note_sprite := &object.NoteObjectSprite{
			object: beatmap.internal.notes[i].BaseNoteObject
		}

		note_sprite.initialize(
			beatmap.internal.notes[i].is_flick,
			beatmap.internal.notes[i].is_critical,
			0 // Always 0, this is a note, not flick
		)

		beatmap.objects << note_sprite
	}

	// Flicker
	for i := 0; i < beatmap.internal.flicks.len; i++ {
		mut flick_sprite := &object.NoteObjectSprite{
			object: beatmap.internal.flicks[i].BaseNoteObject
		}

		flick_sprite.initialize(
			true,
			beatmap.internal.flicks[i].is_critical,
			beatmap.internal.flicks[i].direction
		)

		beatmap.objects << flick_sprite
	}

	// Slider
	for i := 0; i < beatmap.internal.sliders.len; i++ {
		mut slider_head_sprite := &object.NoteObjectSprite{
			object: beatmap.internal.sliders[i].start.BaseNoteObject
		}

		mut slider_tail_sprite := &object.NoteObjectSprite{
			object: beatmap.internal.sliders[i].end.BaseNoteObject
		}

		slider_head_sprite.initialize(
			false,
			beatmap.internal.sliders[i].is_critical,
			10 // Some hacks
		)

		slider_tail_sprite.initialize(
			false,
			beatmap.internal.sliders[i].is_critical,
			11 // Some hacks
		)

		// Body
		mut body := &sprite.Sprite{
			textures: [skin.get_texture("notes/tex_hold_path")],
			always_visible: true,
			origin: vector.top_centre
		}

		// fucky wucky
		distance := (((slider_tail_sprite.object.time.end) - slider_head_sprite.object.time.start) / 56.5) * 4.0
		// println(distance)
		
		body.transforms = slider_head_sprite.sprites[0].transforms.clone()
		body.add_transform(typ: .fade, time: time.Time{slider_head_sprite.sprites[0].time.start - 10.0, slider_head_sprite.sprites[0].time.start}, before: [0.0], after: [255.0])
		body.add_transform(typ: .fade, time: time.Time{beatmap.internal.sliders[i].end.time.end, beatmap.internal.sliders[i].end.time.end + 10.0}, before: [255.0], after: [0.0])

		angle := slider_head_sprite.sprites[0].position.angle_rv(slider_tail_sprite.sprites[0].position.add(x: 0.0, y: 0.0))
		body.angle = angle


		body.reset_size_based_on_texture(size: vector.Vector2{slider_head_sprite.sprites[0].size.x * 1.4, distance})
		body.reset_time_based_on_transforms()
		body.reset_attributes_based_on_transforms()
		

		beatmap.objects << slider_head_sprite
		beatmap.objects << slider_tail_sprite
		beatmap.objects_layer.add(mut body)
	}
}

pub fn (mut beatmap Beatmap) update(update_time f64) {
	beatmap.sprites.update(update_time)
	beatmap.objects_layer.update(update_time)
	

	for i := 0; i < beatmap.objects.len; i++ {
		if update_time >= beatmap.objects[i].time.start - 1000 && update_time <= beatmap.objects[i].time.end + 1000 {
			beatmap.objects[i].update(update_time)
		}
	}

	beatmap.last_update_time = update_time
}

pub fn (mut beatmap Beatmap) draw(arg sprite.CommonSpriteArgument) {
	beatmap.sprites.draw(arg)

	beatmap.switch_to_sekai_camera(arg)
	beatmap.objects_layer.draw(arg)
	for i := 0; i < beatmap.objects.len; i++ {
		if beatmap.last_update_time >= beatmap.objects[i].time.start - 1000 && beatmap.last_update_time <= beatmap.objects[i].time.end + 1000 {
			beatmap.objects[i].draw(arg)
		}
	}
	beatmap.switch_to_normal_camera()
}

// funny
pub fn (mut beatmap Beatmap) switch_to_sekai_camera(arg sprite.CommonSpriteArgument) {
	twod_view := beatmap.debug_view

	// Perspective
    sgl.defaults()
    sgl.load_pipeline(arg.ctx.timage_pip)

    fov := f32(50.0)

    sgl.matrix_mode_projection()
    sgl.perspective(sgl.rad(fov), 1.0, 0.0, 1000.0)

    sgl.matrix_mode_modelview()
	
	if twod_view {
		beatmap.debug_view_sm = (-50.0) * 0.25 + beatmap.debug_view_sm - beatmap.debug_view_sm * 0.25
		sgl.translate(0.0, 0.0, f32(beatmap.debug_view_sm))
		// sgl.rotate(sgl.rad(-60), 1.0, 0.0, 0.0)
    	// sgl.rotate(sgl.rad(0), 0.0, 1.0, 0.0)
	} else {
		beatmap.debug_view_sm = (-13.0) * 0.25 + beatmap.debug_view_sm - beatmap.debug_view_sm * 0.25
		sgl.translate(0.0, 0.0, f32(beatmap.debug_view_sm))
		sgl.rotate(sgl.rad(-60), 1.0, 0.0, 0.0)
    	sgl.rotate(f32(sgl.rad(f32(math.sin(time.global.time / 500.0) * 10.32))), 0.0, 1.0, 0.0)
	}
    

    arg.ctx.draw_rect_filled(-0.5 * 6.5, -7.3, 0.5 * 13, 1, gx.red)
    arg.ctx.draw_line(0, 0, 0, 100, gx.green)
}

pub fn (mut beatmap Beatmap) switch_to_normal_camera() {
	// Reset camera
    sgl.defaults()
    sgl.matrix_mode_projection()
    sgl.ortho(0.0, 1280, 720, 0.0, -1.0, 1.0)
}