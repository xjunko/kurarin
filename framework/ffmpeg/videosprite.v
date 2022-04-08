module ffmpeg
import library.gg

import framework.math.time
import framework.graphic.sprite

import game.x

pub struct VideoSprite {
	sprite.Sprite

	pub mut:
		source      &FFmpegReader = voidptr(0)
		tex_id      int
		last_time   f64
		delta_count f64
		frametime   f64
		ctx         &gg.Context = voidptr(0)
		need_update bool
}

pub fn (mut video VideoSprite) draw(arg sprite.CommonSpriteArgument) {
	if video.need_update {
		video.update_texture()
		video.need_update = false
	}


	if video.is_drawable_at(arg.time) || video.always_visible {
		video.ctx.draw_image_with_config(gg.DrawImageConfig{
			img_id: video.tex_id,
			img_rect: gg.Rect{
				x: f32((x.resolution.resolution.x - video.source.metadata.width) / 2.0),
				y: f32((x.resolution.resolution.y - video.source.metadata.height) / 2.0),
				width: f32(video.source.metadata.width),
				height: f32(video.source.metadata.height)
			},
			color: video.color,
			additive: video.additive
		})
	}
}

pub fn (mut video VideoSprite) update_video() {
	video.source.update()
}

pub fn (mut video VideoSprite) update_texture() {
	video.ctx.update_pixel_data(video.tex_id, video.source.buffer.data)
}

pub fn (mut video VideoSprite) update(time f64) {
	video.Sprite.update(time)

	// Update video frame when needed...
	delta := time - video.last_time
	video.last_time = time

	video.delta_count += delta

	if video.delta_count >= video.frametime {
		video.delta_count -= video.frametime
		video.need_update = true
		video.update_video()
	}
}

pub fn (mut video VideoSprite) draw_and_update(arg sprite.CommonSpriteArgument) {
	video.update(arg.time)
	video.draw(arg)
}

pub fn (mut video VideoSprite) start_video_thread() {
	// go fn (mut video VideoSprite) {
	// 	video.last_time = time.global.time
	// 	for {
	// 		video.update(time.global.time)
	// 		timelib.sleep(time.update_rate_ms)
	// 	}
	// }(mut video)
}

pub fn make_video_sprite(path string, mut ctx &gg.Context) &VideoSprite {
	mut video := &VideoSprite{ctx: ctx, always_visible: true}

	// Load video
	video.source = load_video(path)

	// start ffmpeg
	video.source.initialize_video_data()
	video.source.initialize_ffmpeg()

	// Make a texture for it
	video.tex_id = ctx.new_streaming_image(int(video.source.metadata.width), int(video.source.metadata.height), 4, gg.StreamingImageConfig{})

	// ehh
	video.frametime = 1000.0 / video.source.metadata.fps

	// fade in
	video.add_transform(typ: .fade, time: time.Time{0, 1000}, before: [0.0], after: [255.0])
	video.reset_attributes_based_on_transforms()

	return video
}