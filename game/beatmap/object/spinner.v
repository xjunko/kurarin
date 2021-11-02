module object

import lib.gg

import framework.math.time
import framework.graphic.sprite

pub struct Spinner {
	HitObject
	pub mut:
		spinnercircle &sprite.Sprite = &sprite.Sprite{}
}

pub fn (mut spinner Spinner) draw(ctx &gg.Context, time f64)  {
	
}

pub fn (mut spinner Spinner) initialize_object(mut ctx &gg.Context, last_object IHitObject) {
	preempt := spinner.diff.preempt
	start_time := spinner.time.start - preempt
	end_time := spinner.time.start
	duration := spinner.HitObject.data[5].split(':')[0].f64() - end_time


	spinner.spinnercircle = &sprite.Sprite{
		textures: [ctx.get_texture_from_skin('spinner-circle')]
	}

	spinner.spinnercircle.add_transform(typ: .scale_factor, time: time.Time{end_time-1, end_time-1}, before: [f64(0.5)])
	spinner.spinnercircle.add_transform(typ: .move, time: time.Time{start_time, start_time}, before: [spinner.position.x, spinner.position.y])
	spinner.spinnercircle.add_transform(typ: .fade, time: time.Time{start_time, end_time}, before: [f64(0)], after: [f64(255)])
	spinner.spinnercircle.add_transform(typ: .scale_factor, time: time.Time{end_time, end_time + duration}, before: [f64(1)], after: [f64(0.2)])
	spinner.spinnercircle.add_transform(typ: .fade, time: time.Time{end_time, end_time + duration}, before: [f64(255)], after: [f64(0)])
	spinner.spinnercircle.add_transform(typ: .angle, time: time.Time{end_time, end_time + duration}, before: [f64(0)], after: [f64(5)])
	
	spinner.spinnercircle.reset_time_based_on_transforms()
	spinner.spinnercircle.reset_attributes_based_on_transforms()
	spinner.spinnercircle.reset_image_size()

	spinner.sprites = [spinner.spinnercircle]
}

pub fn (mut spinner Spinner) check_if_mouse_clicked_on_hitobject(x f64, y f64, time f64, osu_space bool) {

}