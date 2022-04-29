module storyboard

import os
import sync
import math
import library.gg

import framework.ffmpeg
import framework.logging

import framework.math.time as time2
import framework.math.vector
import framework.math.easing
import framework.math.transform
import framework.graphic.sprite

pub const (
	storyboard_scale = f64(1.5) // TODO: put this into game.x or smth
)

pub struct Storyboard {
	pub mut:
		ctx  	&gg.Context = voidptr(0)
		root 	string
		sprites []&sprite.Sprite
		video   &ffmpeg.VideoSprite = voidptr(0)

		last_boost f64
		last_time f64
		thread_started bool
		mutex &sync.Mutex = sync.new_mutex()

		// Cache
		cache   map[string]gg.Image
		// TODO: layering
}

pub fn (mut storyboard Storyboard) get_image(path string) gg.Image {
	if path !in storyboard.cache {
		storyboard.cache[path] = storyboard.ctx.create_image(path)
	}

	return storyboard.cache[path]
}

pub fn (mut storyboard Storyboard) update_time(time f64) {
	storyboard.last_time = time
}

pub fn (mut storyboard Storyboard) update_boost(boost f64) {
	storyboard.last_boost = boost
}

pub fn (mut storyboard Storyboard) update(time f64) {
	// remove and update
	for mut sprite in storyboard.sprites {
		// Remove
		if time >= sprite.time.end && !sprite.always_visible {
			storyboard.sprites.delete(storyboard.sprites.index(sprite))
			continue
		}

		if sprite.is_drawable_at(time) {
			sprite.update(time)
		}
	}

	// Background video
	if storyboard.video != voidptr(0) {
		storyboard.video.update(storyboard.last_time)	
	}
}

pub fn (mut storyboard Storyboard) start_thread() {
	if storyboard.thread_started {
		return
	}

	storyboard.thread_started = true

	go fn (mut storyboard Storyboard){
		mut limiter := time2.Limiter{120, 0, 0}
		for storyboard.thread_started {
			storyboard.mutex.@lock()
			storyboard.update(storyboard.last_time)
			storyboard.mutex.unlock()
			limiter.sync()
		}
	}(mut storyboard)
}

pub fn (mut storyboard Storyboard) draw() {
	for mut sprite in storyboard.sprites {
		if sprite.is_drawable_at(storyboard.last_time) || sprite.always_visible {
			pos := sprite.position
					.scale(storyboard_scale)
					.sub(sprite.origin.multiply(sprite.size.scale(storyboard.last_boost * storyboard_scale)))
					.add(x: 105 * storyboard_scale, y: 0)
			
			storyboard.ctx.draw_image_with_config(gg.DrawImageConfig{
					img: sprite.get_texture(),
					img_id: sprite.get_texture().id,
					img_rect: gg.Rect{
						x: f32(pos.x),
						y: f32(pos.y),
						width: f32(sprite.size.x * (storyboard.last_boost * storyboard_scale)),
						height: f32(sprite.size.y * (storyboard.last_boost * storyboard_scale))
					},
					color: sprite.color,
					rotate: f32(sprite.angle)
					additive: sprite.additive
			})
		}
	}

	if storyboard.video != voidptr(0) {
		storyboard.video.draw(ctx: storyboard.ctx, scale: storyboard.last_boost)
	}
}

// "utils"
pub fn parse_header(s string) string {
	if s.starts_with('[') {
		return s.replace('[', '').replace(']', '').trim_space()
	}

	return ''
}

pub fn parse_variable(s string) []string {
	return s.trim_space().split('=')
}

pub fn parse_comma(s string) []string {
	return s.trim_space().split(',')
}

pub fn cut_whites(s string) (string, int) {
	for i, c in s {
		if c.is_letter() || c.is_digit() {
			return s[i..], i
		}
	}

	return s, 0
}

//
pub fn (mut storyboard Storyboard) parse_lines(lines_ []string) {
	mut current_section := ''
	mut current_sprite := ''
	mut commands := []string{}
	mut variables := map[string]string{}
	mut lines := lines_.clone()
	
	for mut line in lines {
		if line.starts_with("//") || line.trim_space().len == 0 {
			continue
		}

		section := parse_header(line)

		if section != "" {
			current_section = section
			continue
		}

		match current_section {
			'Variables' {
				items := parse_variable(line)
				variables[items[0]] = items[1]
			}

			'Events' {
				if line.contains("$") {
					for key, value in variables {
						if line.contains(key) {
							line = line.replace(key, value)
						}
					}
				}
				
				if line.starts_with("Sprite") || line.starts_with("Animation") {
					if current_sprite.len != 0 {
						// logging.debug("Loading sprite: ${current_sprite} - ${commands.len} events!")
						storyboard.load_sprite(current_sprite, commands)
					}

					current_sprite = *line // ok lol
					commands = []
				} else if line.starts_with(' ') || line.starts_with("_") {
					commands << line
				}
			}

			else {}
		}
	}

	if current_sprite.len != 0 {
		storyboard.load_sprite(current_sprite, commands)
	}
}

//
pub fn (mut storyboard Storyboard) load_sprite(header string, commands []string) {
	items := parse_comma(header)

	mut img_path := os.join_path(storyboard.root, items[3].replace('"', '').trim_space()).replace("\\", "/") // Weird linux thing

	// ??? what
	if !img_path.to_lower().ends_with('.png') && !img_path.to_lower().ends_with('.jpg') {
		logging.debug('> sus filepath in storyboard: ${img_path}')
		img_path += ".png"
	}
	
	// real shit
	if items[0] == 'Sprite' {
		position := vector.Vector2{
			x: items[4].f64(),
			y: items[5].f64()
		}
		origin := vector.parse_origin(items[2])
	
		mut sprite := &sprite.Sprite{
			origin: origin,
			textures: [storyboard.get_image(img_path)] // ez
		}

		sprite.position.x = position.x
		sprite.position.y = position.y
		transforms := parse_sprite_commands(commands)

		// FIXME: This is a hack
		// println(transforms.len)
		for transform in transforms {
			sprite.add_transform(transform)
		}

		if sprite.transforms.len > 0 {
			sprite.reset_size_based_on_texture()
			sprite.reset_attributes_based_on_transforms()
			storyboard.sprites << sprite 
		}	

		// check for stuff that doesnt have scale transforms
		mut has_been_scaled := false
		for transform in sprite.transforms {
			if transform.typ == .scale || transform.typ == .scale_factor {
				has_been_scaled = true
			}
		}

		if !has_been_scaled {
			sprite.reset_size_based_on_texture()
			sprite.raw_size = sprite.raw_size.scale(1 / storyboard_scale)
			sprite.size = sprite.size.scale(1 / storyboard_scale)
		}
	}
}

pub fn parse_sprite_commands(commands []string) []&transform.Transform {
	mut transforms := []&transform.Transform{}
	mut current_loop := &LoopProcessor{}
	mut loop_depth := -1
	current_loop = voidptr(0) // HACK: epic trol

	for subcommand in commands {
		mut command := subcommand.split(",")
		mut removed := 0

		command[0], removed = cut_whites(command[0])

		if command[0] == "T" {
			continue // LOL NO
		}

		if removed == 1 {
			if current_loop != voidptr(0) {
				transforms << current_loop.finalize()

				current_loop = voidptr(0)
				loop_depth = -1
			}

			if command[0] != "L" {
				transforms << parse_command(mut command)
			}
		}

		if command[0] == "L" {
			current_loop = make_loop_processor(command)
			loop_depth = removed + 1
		} else if removed == loop_depth && current_loop != voidptr(0) {
			current_loop.add(mut command)
		}
		
	}

	if current_loop != voidptr(0) {
		transforms << current_loop.finalize()
	}

	return transforms
}

pub fn parse_command(mut items []string) []&transform.Transform {
	mut transforms := []&transform.Transform{}

	if items[0] == 'T' || items[0] == 'L' {
		panic("T or L command called in generic parser.")
	}

	command_type := items[0]
	easing := easing.get_easing_from_enum(easing.Easing(items[1].i8())) // looks fucked

	mut start_time := items[2].f64()

	if items[3] == '' {
		items[3] = items[2]
	}

	mut end_time := items[3].f64()
	mut arguments := 0

	// Make sure end_time is greater than start
	end_time = math.max(start_time, end_time)

	if end_time == start_time {
		end_time = start_time + 1
	}
	

	match command_type {
		'F', 'R', 'S', 'MX', 'MY' {
			arguments = 1
		}
		'M', 'V' {
			arguments = 2
		}
		'C' {
			arguments = 3
		}
		else {}
	}

	mut parameters := items[4..]
	if arguments == 0 {
		match parameters[0] {
			"A" { 
				transforms << &transform.Transform{typ: .additive, time: time2.Time{start_time, end_time}, before: [1.0]}
			}
			"V" {
				transforms << &transform.Transform{typ: .flip_vertically, time: time2.Time{start_time, end_time}, before: [1.0]}
			}
			"H" {
				transforms << &transform.Transform{typ: .flip_horizontally, time: time2.Time{start_time, end_time}, before: [1.0]}
			}
			else {}
		}

		return transforms
	}
	
	mut sections := [][]f64{}
	sections_length := parameters.len / arguments

	for i in 0 .. sections_length {
		sections << []f64{}

		for j in 0 .. arguments {
			sections[i] << parameters[arguments * i + j].f64()

			if command_type == 'F' {
			sections[i][j] *= 255
			}
		}
	}

	if sections_length == 1 {
		sections << sections[0].clone()
	}

	match command_type {
		'F' {
			transforms << &transform.Transform{
				typ: .fade, 
				easing: easing, 
				time: time2.Time{start_time, end_time},
				before: sections[0],
				after: sections[1]
			}
		}

		'R' {
			transforms << &transform.Transform{
				typ: .angle, 
				easing: easing, 
				time: time2.Time{start_time, end_time},
				before: sections[0],
				after: sections[1]
			}
		}

		'S' {
			transforms << &transform.Transform{
				typ: .scale_factor, 
				easing: easing, 
				time: time2.Time{start_time, end_time},
				before: sections[0],
				after: sections[1]
			}
		}

		'MX' {
			transforms << &transform.Transform{
				typ: .move_x, 
				easing: easing, 
				time: time2.Time{start_time, end_time},
				before: sections[0],
				after: sections[1]
			}
		}

		'MY' {
			transforms << &transform.Transform{
				typ: .move_y, 
				easing: easing, 
				time: time2.Time{start_time, end_time},
				before: sections[0],
				after: sections[1]
			}
		}

		'M' {
			transforms << &transform.Transform{
				typ: .move, 
				easing: easing, 
				time: time2.Time{start_time, end_time},
				before: sections[0],
				after: sections[1]
			}
		}

		'V' {
			transforms << &transform.Transform{
				typ: .scale, 
				easing: easing, 
				time: time2.Time{start_time, end_time},
				before: sections[0],
				after: sections[1]
			}
		}

		'C' {
			transforms << &transform.Transform{
				typ: .color, 
				easing: easing, 
				time: time2.Time{start_time, end_time},
				before: sections[0],
				after: sections[1]
			}
		}

		else { logging.debug('> Storyboard: Invalid command => ${command_type}') }
	}

	return transforms
}

//
pub fn parse_storyboard(path string, mut ctx &gg.Context) &Storyboard {
	mut sb := &Storyboard{ctx: ctx}
	sb.root = os.dir(path)

	if os.exists(path) {
		mut lines := os.read_lines(path) or { panic("uwu i fucked up: ${err}") }
		sb.parse_lines(lines)
	}

	return sb
}