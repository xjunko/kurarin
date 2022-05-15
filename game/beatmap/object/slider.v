module object

import math

import framework.graphic.sprite
import framework.math.easing
import framework.math.vector
import framework.math.glider
import framework.math.time
import framework.logging

import game.beatmap.difficulty
import game.beatmap.timing
import game.audio
import game.skin

import curves
import graphic

pub struct TickPoint {
	pub mut:
		time f64
		pos vector.Vector2	
		is_reverse bool
		// fade &glider.Glider = &glider.Glider{}
		// scale &glider.Glider = &glider.Glider{}
}

pub struct Pathline {
	pub mut:
		time1 i64
		time2 i64
		line  curves.Linear
}

pub struct Slider {
	HitObject

	pub mut:
		timing          timing.Timings
		timing_point    timing.TimingPoint
		hitcircle 		&Circle

		// Slider shit
		repeated        int
		pixel_length    f64
		duration        f64		
		points          []vector.Vector2
		curve           curves.MultiCurve
		typ             string

		//
		tick_points []TickPoint
		tick_reverse []TickPoint
		score_points []TickPoint
		score_points_lazer []TickPoint
		score_path []Pathline

		// 
		slider_overlay_sprite &sprite.Sprite = &sprite.Sprite{}
		slider_b_sprite  	  &sprite.Sprite = &sprite.Sprite{}
		

		sprites         	  []&sprite.Sprite
		slider_renderer_attr  &graphic.SliderRendererAttr = voidptr(0)
		slider_renderer_fade  &glider.Glider = voidptr(0)

		// Sample
		samples         []int
		sample_sets     []int
		addition_sets   []int // TODO

		// angle
		start_angle f64
		end_angle f64

		// temp
		is_sliding bool
		done             bool
		last_slider_time int
		last_time        f64

}

pub fn (mut slider Slider) set_combo_number(combo int) {
	slider.hitcircle.set_combo_number(combo)
}

pub fn (mut slider Slider) set_id(id int) {
	slider.HitObject.set_id(id)
	slider.hitcircle.set_id(id)
}

pub fn (mut slider Slider) get_number() i64 {
	return slider.HitObject.get_id()
}

pub fn (mut slider Slider) draw(arg sprite.CommonSpriteArgument) {
	// // DEBUG: some angle lines, uncomment to see.
	// local := arg.camera.translate(slider.slider_b_sprite.position)
	// distance := local.distance(arg.camera.translate(slider.position))
	// angle := slider.slider_b_sprite.position.angle_rv(slider.position) + math.pi
	// angled := local.add(x: math.cos(angle) * distance, y: math.sin(angle) * distance)
	// arg.ctx.draw_line_with_config(f32(local.x), f32(local.y), f32(angled.x), f32(angled.y), gg.PenConfig{color: gx.white, thickness: 16})

	// Normal shit
	slider.hitcircle.draw(arg) // Draw hitcircle

	// Draw the easy stuff first
	for mut sprite in slider.sprites {
		sprite.draw(arg)
	}
}

pub fn (mut slider Slider) hit_edge(index int, time f64, is_hit bool) {
	if index == 0 {
		slider.arm_start(is_hit, time)
	} else {
		// slider.play_hitsound_generic(index)
	}

	if is_hit {
		// slider.play_hitsound(index)
		slider.play_hitsound_edge(index)
	}
}

pub fn (mut slider Slider) play_hitsound_edge(index int) {
	mut sample_set := slider.sample_sets[index]

	if sample_set == 0 && index == 0 {
		sample_set = slider.hitsound.sample_set
	}

	slider.play_hitsound_generic(sample_set, slider.addition_sets[index], slider.samples[index], slider.timing.get_point_at(slider.time.start + math.floor(f64(index) * slider.duration) + 5))
}

pub fn (mut slider Slider) play_hitsound(index int) {
	slider.play_hitsound_generic(
		slider.sample_sets[index],
		slider.addition_sets[index],
		slider.samples[index],
		slider.timing.get_point_at(slider.time.start + math.floor(f64(index) * slider.duration) + 5)
	)
}

pub fn (mut slider Slider) play_hitsound_generic(sample_set_ int, addition_set_ int, sample int, point timing.TimingPoint) {
	mut sample_set := sample_set_
	mut addition_set := addition_set_

	if sample_set == 0 {
		sample_set = slider.hitsound.sample_set

		if sample_set == 0 {
			sample_set = point.sample_set
		}
	}

	if addition_set == 0 {
		addition_set = slider.hitsound.addition_set
	}

	audio.play_sample(
		sample_set,
		addition_set,
		sample,
		point.sample_index,
		point.sample_volume
	)
}

pub fn (mut slider Slider) update(time f64) bool {
	slider.slider_renderer_fade.update(time)
	slider.hitcircle.update(time)

	for mut sprite in slider.sprites {
		sprite.update(time)
	}

	// HACK: MOVe this to somwhre else
	slider_current_position := slider.get_position_at_lazer(time)
	slider.slider_overlay_sprite.position.x = slider_current_position.x
	slider.slider_overlay_sprite.position.y = slider_current_position.y
	slider.slider_b_sprite.position.x = slider_current_position.x
	slider.slider_b_sprite.position.y = slider_current_position.y

	// SliderBall angle
	if time >= slider.time.start && time <= slider.time.end - 5.0 {
		slider_future_infront_position := slider.get_position_at_lazer(math.min<f64>(time + 1.0, slider.time.end))
		slider.slider_b_sprite.angle = (slider_current_position.angle_rv(slider_future_infront_position) * 180 / math.pi) * -1.0 + 180.0
		// ^^^^ FIXME: what the fuck huh
	}

	// Generate renderer way before the slider appears
	if time >= (slider.time.start - slider.diff.preempt - 50.0) && slider.slider_renderer_attr == voidptr(0) {
		slider.generate_slider_renderer()
	}

	if slider.is_sliding {
		for i := 1; i < slider.repeated; i++ {
			edge_time := slider.time.start + math.floor(f64(i * slider.duration))

			if slider.last_time < edge_time && time >= edge_time {
				slider.hit_edge(int(i), time, true)
			}
		}
	}

	slider.last_time = time
	return false
}

pub fn (mut slider Slider) post_update(time f64) {
	logging.debug("Freeing slider.")
	slider.slider_renderer_attr.free()
}

pub fn (mut slider Slider) is_retarded() bool {
	return slider.score_path.len == 0 || slider.time.start == slider.time.end
}

pub fn (mut slider Slider) arm_start(clicked bool, time f64) {
	slider.hitcircle.arm(clicked, time)
}

pub fn (mut slider Slider) init_slide(_time f64) {
	if _time < slider.time.start || _time > slider.time.end {
		return
	}

	size_ratio := f64((slider.diff.circle_radius * 1.05 * 2) / 128)

	slider.slider_overlay_sprite.reset_transform()
	mut start_time := _time
	fade_in_end := math.min<f64>(start_time + 180, slider.time.end)

	slider.slider_overlay_sprite.add_transform(typ: .fade, time: time.Time{start_time, math.min<f64>(start_time + 60, slider.time.end)}, before: [0.0], after: [255.0])
	slider.slider_overlay_sprite.add_transform(typ: .scale_factor, time: time.Time{start_time, fade_in_end}, before: [size_ratio * 0.5], after: [size_ratio * 1.0])

	slider.slider_overlay_sprite.add_transform(typ: .fade, time: time.Time{slider.time.end, slider.time.end + 200}, before: [255.0], after: [0.0])
	slider.slider_overlay_sprite.add_transform(typ: .scale_factor, time: time.Time{slider.time.end, slider.time.end + 200}, before: [size_ratio * 1.0], after: [size_ratio * 0.8])

	slider.slider_overlay_sprite.reset_attributes_based_on_transforms()

	// TODO: Follower thud-thud thingy
	// https://github.com/Wieku/danser-go/blob/2b0ec47f1b93a338df37ece927743d3b92288cc0/app/beatmap/objects/slider.go#L755
	// fade_base := 200.0
	// mut fade_time := fade_base

	// if slider.score_points.len >= 2 {
	// 	fade_time = math.min<f64>(fade_time, slider.score_points[1].time - slider.score_points[0].time)
	// }

	// end_value := 1.1 - (fade_time / fade_base) * 0.1

	// for i := 0; i < slider.score_points.len-1; i++ {
	// 	mut p := &slider.score_points[i]
	// 	end_time := p.time + fade_time

	// 	if end_time < fade_in_end {
	// 		continue
	// 	}

	// 	start_time = p.time
	// 	mut start_value := 1.1

	// 	if start_time < fade_in_end {
	// 		slider.slider_overlay_sprite.add_transform(typ: .scale_factor, time: time.Time{slider.time.start, math.min<f64>(slider.time.end, end_time)}, before: [size_ratio * start_value], after: [size_ratio * end_value])
	// 	}
	// }

	slider.is_sliding = true
}

pub fn (mut slider Slider) kill_slide(_time f64) {
	slider.slider_overlay_sprite.reset_transform()

	size_ratio := f64((slider.diff.circle_radius * 1.05 * 2) / 128)
	mut next_point := slider.time.end 

	for point in slider.score_points {
		if point.time > _time {
			next_point = point.time
			break
		}
	}

	// Force follower to normal size
	slider.slider_overlay_sprite.add_transform(typ: .scale_factor, easing: easing.quad_out, time: time.Time{math.min<f64>(_time, next_point - 1.0), math.min<f64>(_time + 100, next_point - 1.0)}, before: [slider.slider_overlay_sprite.size.x / slider.slider_overlay_sprite.raw_size.x], after: [size_ratio])

	slider.slider_overlay_sprite.add_transform(typ: .fade, time: time.Time{next_point - 100, next_point}, before: [255.0], after: [0.0])
	slider.slider_overlay_sprite.add_transform(typ: .scale_factor, time: time.Time{next_point - 100, next_point}, before: [size_ratio], after: [size_ratio * 1.5])
	
	// TODO:
	// https://github.com/Wieku/danser-go/blob/2b0ec47f1b93a338df37ece927743d3b92288cc0/app/beatmap/objects/slider.go#L780
	slider.is_sliding = false

}

pub fn (mut slider Slider) set_boost_level(boost f32) {
	slider.HitObject.set_boost_level(boost)
	slider.hitcircle.set_boost_level(boost)
}

pub fn (mut slider Slider) set_timing(t timing.Timings) {
	slider.timing = t
	slider.timing_point = t.get_point_at(slider.time.start)
	slider.hitcircle.set_timing(t)

	// Slider data
	slider.repeated = slider.data[6].int()
	slider.pixel_length = slider.data[7].f64()

	// Duration per one round (duration*n if its a reverse slider)
	slider.duration = slider.timing.get_point_at(slider.time.start).get_beat_length() * slider.pixel_length / (100 * slider.timing.slider_multiplier)
	slider.time.end += slider.duration * f64(slider.repeated)

	// Samples
	slider.samples = []int{len: int(slider.repeated) + 1}
	slider.sample_sets = []int{len: int(slider.repeated) + 1}
	slider.addition_sets = []int{len: int(slider.repeated) + 1}

	// Sample
	if slider.data.len > 8 {
		data := slider.data[8].split("|")
		for i, v in data {
			slider.samples[i] = v.int()
		}
	}

	// Sets
	if slider.data.len > 9 {
		data := slider.data[9].split("|")
		for i, v in data {
			items := v.split(":")
			slider.sample_sets[i] = items[0].int()
			slider.addition_sets[i] = items[1].int()
		}
	}

	// Initialize slider curve
	slider.generate_slider_path()

	// WARNING: God awful calculation starts here
	nan_timing_point := math.is_nan(slider.timing_point.beatlength)

	lines := slider.curve.get_lines()

	mut start_time := slider.time.start

	velocity := slider.timing.get_velocity(slider.timing_point)

	c_length := slider.curve.get_length()

	span_duration := c_length * 1000.0 / velocity

	end_time_lazer := slider.time.start + c_length * 1000.0 * f64(slider.repeated) / velocity

	min_distance_from_end := velocity * 0.01
	mut tick_distance := slider.timing.get_tick_distance(slider.timing_point)

	if slider.curve.get_length() > 0.0 && tick_distance > slider.pixel_length {
		tick_distance = slider.pixel_length
	}

	// Lazer-like score point calculation, clean but not reliable
	for span := 0; span < int(slider.repeated); span++ {
		span_start_time := slider.time.start + f64(span) * span_duration
		reversed := (span % 2) == 1

		// Skip ticks if timingpoint has nan beatlength
		for d := tick_distance; d <= c_length && !nan_timing_point; d += tick_distance {
			if d >= c_length - min_distance_from_end {
				break
			}

			// Always generate ticks from the start of the path rather than the span
			// To ensure that ticks in repeat spans are positioned identically 
			// to those in non-repeat spans
			mut time_progress := d / c_length

			if reversed {
				time_progress = 1 - time_progress
			}

			slider.score_points_lazer << TickPoint{
				time: span_start_time + time_progress * span_duration
			}
		}

		if span < int(slider.repeated) - 1{
			slider.score_points_lazer << TickPoint{
				time: span_start_time + span_duration,
				is_reverse: true
			}
		} else {
			slider.score_points_lazer << TickPoint{
				time: math.max<f64>(
					slider.time.start + (end_time_lazer - slider.time.start) / 2.0,
					end_time_lazer - 36.0
				)
			}
		}
	}

	mut scoring_length_total := 0.0
	mut scoring_distance := 0.0

	// Stable-like score point processing, god awful
	for i := i64(0); i < slider.repeated; i++ {
		mut distance_to_end := f64(slider.curve.get_length())
		mut skip_tick := nan_timing_point

		reverse := (i % 2) == 1

		mut start := 0
		mut end := lines.len
		mut direction := 1

		if reverse {
			start = lines.len - 1
			end = -1
			direction = -1
		}

		for j := start; j != end; j+= direction {
			line := &lines[j]

			mut p1, mut p2 := line.p1, line.p2

			if reverse {
				p1, p2 = p2, p1
			}

			distance := line.get_length()

			progress := 1000.0 * f64(distance) / velocity

			slider.score_path << Pathline{
				time1: i64(start_time),
				time2: i64(start_time + progress),
				line: curves.make_linear(p1, p2)
			}

			start_time += progress
			slider.time.end = math.floor(start_time)
			
			scoring_distance += f64(distance)

			for scoring_distance >= tick_distance && !skip_tick {
				scoring_length_total += tick_distance
				scoring_distance -= tick_distance
				distance_to_end -= tick_distance

				skip_tick = distance_to_end <= min_distance_from_end

				if skip_tick {
					break
				}

				score_time := slider.time.start + math.floor(
					f64(f32(scoring_length_total) * 1000.0) / velocity
				)

				point := TickPoint{
					score_time,
					slider.get_position_at_lazer(score_time),
					false
				}

				slider.tick_points << point
				slider.score_points << point
			}
		}

		scoring_length_total += scoring_distance

		score_time := slider.time.start + math.floor((f64(f32(scoring_length_total)) / velocity) * 1000.0)
		point := TickPoint{
			score_time,
			slider.get_position_at_lazer(score_time),
			true
		}

		slider.tick_reverse << point
		slider.score_points << point

		if skip_tick {
			scoring_distance = 0
		} else {
			scoring_length_total -= tick_distance - scoring_distance
			scoring_distance = tick_distance - scoring_distance
		}

	}

	$if debug {
		logging.debug("TickPoint: ${slider.tick_points.len} | ScorePoint: ${slider.score_points.len} - Lazer: ${slider.score_points_lazer.len} | TickReverse: ${slider.tick_reverse.len} | ScorePath: ${slider.score_path.len}")
	}

	slider.duration = (slider.time.end - slider.time.start) / f64(slider.repeated)
}

pub fn (mut slider Slider) generate_slider_path() {
	logging.debug("Generating slider path!")

	slider_points_raw := slider.data[5].split("|")
	slider.typ = slider_points_raw[0]

	mut slider_points := []vector.Vector2{}
	slider_points << slider.position

	for i := 1; i < slider_points_raw.len; i++ {
		items := slider_points_raw[i].split(":")
		slider_points << vector.Vector2{items[0].f64(), items[1].f64()}
	}
	
	// oh god
	slider.curve = curves.new_multi_curve_t(slider_points_raw[0], slider_points, slider.pixel_length)
	slider.get_slider_points() // Generate points
	slider.end_position = slider.get_position_at_lazer(slider.time.end)

	slider.start_angle = slider.get_start_angle()

	if slider.curve.lines.len > 0 {
		slider.end_angle = slider.get_end_angle()
	} else {
		slider.end_angle = slider.start_angle + math.pi
	}

	// Done
	logging.debug("Done generating slider path!")
}

pub fn (mut slider Slider) generate_slider_follow_circles() {
	// not poggers
	slider.slider_overlay_sprite.textures << skin.get_texture("sliderfollowcircle")
	slider.slider_b_sprite.textures << skin.get_frames("sliderb")

	mut slider_sprites := []&sprite.Sprite{}
	slider_sprites << slider.slider_overlay_sprite
	slider_sprites << slider.slider_b_sprite

	// Color
	slider.slider_b_sprite.add_transform(typ: .color, time: time.Time{slider.time.start, slider.time.start}, before: slider.color)

	size_ratio := f64((slider.diff.circle_radius * 1.05 * 2) / 128)

	for i, mut sprite in slider_sprites {
		if i == 1 {
			sprite.add_transform(typ: .fade, time: time.Time{slider.time.end, slider.time.end + 120.0}, before: [255.0], after: [0.0])
		}
		sprite.add_transform(typ: .scale_factor, time: time.Time{slider.time.start, slider.time.start}, before: [size_ratio])

		sprite.reset_size_based_on_texture()
		sprite.reset_attributes_based_on_transforms()
	}

	slider.sprites << slider.slider_overlay_sprite
	slider.sprites << slider.slider_b_sprite
}

pub fn (mut slider Slider) generate_slider_tickpoints() {
	texture := skin.get_texture("sliderscorepoint")
	size_ratio := f64((slider.diff.circle_radius * 1.05 * 2) / 128)

	// Nice variable name, weiku.
	// https://github.com/Wieku/danser-go/blob/10faa98060a2dca369ff2aaf49e18496c8f4a008/app/beatmap/objects/slider.go#L440
	sl_sn_in_s := slider.time.start - slider.diff.preempt
	sl_sn_in_e := slider.time.start - slider.diff.preempt * 2.0/3.0 * 1.0 + slider.duration * 0.0

	for mut p in slider.tick_points {
		mut a := (p.time - slider.time.start) / 2.0 + slider.time.start - slider.diff.preempt * 2.0/3.0
		mut fs := (p.time - slider.time.start) / slider.duration

		if fs < 1.0 {
			a = math.max<f64>(fs * (sl_sn_in_e - sl_sn_in_s) + sl_sn_in_s, a)
		}

		end_time := math.min<f64>(a + 150.0, p.time - 36.0)

		// TODO: bruh
		mut sprite := &sprite.Sprite{}
		sprite.textures << texture

		sprite.add_transform(typ: .move, time: time.Time{slider.time.start, slider.time.end}, before: [p.pos.x, p.pos.y])
		sprite.add_transform(typ: .scale_factor, time: time.Time{a, end_time}, before: [size_ratio * 0.5], after: [size_ratio * 1.2])
		sprite.add_transform(typ: .scale_factor, easing: easing.quad_out, time: time.Time{end_time, end_time + 150.0}, before: [size_ratio * 1.2], after: [size_ratio * 1.0])
		sprite.add_transform(typ: .fade, time: time.Time{a, end_time}, before: [0.0], after: [255.0])
		sprite.add_transform(typ: .fade, time: time.Time{p.time, p.time + 16.0}, before: [255.0], after: [0.0])
		sprite.reset_size_based_on_texture()
		sprite.reset_attributes_based_on_transforms()

		slider.sprites << sprite
	}
}

pub fn (mut slider Slider) generate_slider_repeat_circle() {
	if slider.repeated < 2 { return }
	
	slider.get_slider_points() // Make slider points

	size_ratio := f64((slider.diff.circle_radius * 1.05 * 2) / 128)

	for i := 1; i <= slider.repeated; i++ {
		if i == slider.repeated {
			return // This is the last round, return
		}

		circle_time := slider.time.start + math.floor(slider.duration * f64(i))
		mut appear_time := slider.time.start - math.floor(slider.diff.preempt)

		if i > 1 {
			appear_time = circle_time - math.floor(slider.duration * 2)
		}

		// 
		mut position := slider.position
		mut angle := slider.end_angle

		// O----<O Start to Finish
		if (i % 2) == 1 {
			position = slider.points[slider.points.len - 1]
			angle = slider.start_angle
		}

		mut sprite := &sprite.Sprite{}
		sprite.textures << skin.get_texture("reversearrow")
		sprite.add_transform(typ: .move, time: time.Time{appear_time, appear_time}, before: [position.x, position.y])
		
		sprite.add_transform(typ: .scale_factor, time: time.Time{appear_time, appear_time}, before: [size_ratio])
		sprite.add_transform(typ: .angle, time: time.Time{appear_time, appear_time}, before: [angle])
		sprite.add_transform(typ: .fade, time: time.Time{appear_time, math.min<f64>(circle_time, appear_time + 150.0)}, before: [0.0], after: [255.0])
		sprite.add_transform(typ: .fade, time: time.Time{circle_time, circle_time + difficulty.hit_fade_out}, before: [255.0], after: [0.0])
		sprite.add_transform(typ: .scale_factor, easing: easing.quad_out, time: time.Time{circle_time, circle_time + difficulty.hit_fade_out}, before: [size_ratio], after: [size_ratio * 1.4])
		sprite.reset_size_based_on_texture()
		sprite.reset_attributes_based_on_transforms()

		bounce_start_time := math.min<f64>(slider.diff.preempt, 15000)
		for t := f64(slider.time.start) - bounce_start_time; t < circle_time; t += 300.0 {
			length := math.min(300.0, circle_time - t)
			sprite.add_transform(typ: .scale_factor, time: time.Time{t, t+length}, before: [size_ratio * 1.3], after: [size_ratio * 1.0])
		}

		slider.sprites << sprite
	}
}

pub fn (mut slider Slider) generate_slider_renderer() {
	slider.slider_renderer_attr = graphic.make_slider_renderer_attr(
		slider.diff.circle_radius, slider.get_slider_points(), slider.pixel_length
	)
}

pub fn (mut slider Slider) get_slider_points() []vector.Vector2 {
	if slider.points.len == 0 {
		slider_quality := 100.0 // TODO: Move to settings
		length := slider.curve.get_length()
		num_points := math.min<f64>(math.ceil(length * (slider_quality / 100.0)), 10000)

		if num_points > 0 {
			for i := 0; i < int(num_points); i++ {
				slider.points << slider.curve.point_at(f64(i) / f64(num_points))
			}
		}
	}

	return slider.points
}

pub fn (mut slider Slider) get_position_at_stable(time f64) vector.Vector2 {
	if slider.is_retarded() {
		return slider.position
	}

	mut index := 0

	for i := 0; i < slider.score_path.len; i++ {
		if f64(slider.score_path[i].time2) >= time {
			index = i
			break
		}
	}

	p_line := slider.score_path[int(math.clamp(index, 0, slider.score_path.len - 1))]
	clamped := math.clamp(time, f64(p_line.time1), f64(p_line.time2))

	mut pos := vector.Vector2{}

	if p_line.time2 == p_line.time1 {
		pos = p_line.line.p2
	} else {
		pos = p_line.line.point_at(
			f32(clamped - f64(p_line.time1)) / 
			f32(p_line.time2 - p_line.time1)
		)
	}

	return pos
}

pub fn (mut slider Slider) get_position_at_lazer(time f64) vector.Vector2 {
	t1 := math.clamp(time, slider.time.start, slider.time.end)
	mut progress := (t1 - slider.time.start) / slider.duration

	progress = math.mod(progress, 2)

	if progress >= 1 {
		progress = 2 - progress
	}

	return slider.curve.point_at(progress)
}

pub fn (mut slider Slider) set_difficulty(diff difficulty.Difficulty) {
	// Set color to parent hitcircle also
	slider.hitcircle.color = slider.color

	slider.diff = diff
	slider.hitcircle.set_difficulty(diff)

	// FadeAnimation
	slider.slider_renderer_fade = glider.new_glider(0.0)
	slider.slider_renderer_fade.add_event(slider.time.start - slider.diff.preempt, slider.time.start - (slider.diff.preempt - slider.diff.fade_in), 1.0)
	slider.slider_renderer_fade.add_event_start(slider.time.end, slider.time.end + difficulty.hit_fade_out, 1.0, 0.0)

	// Make points n shit
	slider.generate_slider_tickpoints()
	slider.generate_slider_repeat_circle()
	slider.generate_slider_follow_circles()
}

pub fn (mut slider Slider) get_start_angle() f64 {
	// TODO: Fix this
	return slider.position.angle_rv(slider.get_position_at_lazer(slider.time.start + math.min<f64>(10, slider.duration)))
}

pub fn (mut slider Slider) get_end_angle() f64 {	
	// TODO: Fix this
	return slider.end_position.angle_rv(slider.get_position_at_lazer(slider.time.end - math.min<f64>(10, slider.duration)))
}


pub fn make_slider(items []string) &Slider {
	mut hslider := &Slider{
		HitObject: common_parse(items, 10),
		hitcircle: make_circle(items)
	}

	hslider.hitcircle.inherited = true

	return hslider
}
