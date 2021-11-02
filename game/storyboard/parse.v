module storyboard

import os
import lib.gg

import framework.math.vector
import framework.math.easing
import framework.math.time as time2

import framework.graphic.canvas
import framework.graphic.sprite

import game.math.resolution

// Not really the best way to do this but eh who cares
pub struct Storyboard {
	pub mut:
		ctx        &gg.Context = voidptr(0)
		background &canvas.Canvas = &canvas.Canvas{size: &vector.Vector2{854, 480}}

		root       string
		// Todo: use other layers
		// other_layers_and_shit_etc &canvas.Canvas = &canvas.Canvas{} 
}

pub fn (mut storyboard Storyboard) update(time f64) {
	storyboard.background.update(time)
}

pub fn (mut storyboard Storyboard) draw(time f64) {
	storyboard.background.draw(storyboard.ctx, time)
}

// bruh
pub fn parse_header(s string) string {
	ss := s.clone().trim_space()

	if ss.starts_with('[') {
		return ss.replace("[", '').replace("]", '').trim_space()
	}

	return ''
}

pub fn parse_variable(s string) []string {
	return s.trim_space().split('=')
}

[inline]
pub fn parse_comma(s string) []string {
	return s.trim_space().split(',')
}


//
pub fn parse_storyboard(mut ctx &gg.Context, path string) &Storyboard {
	mut sb := &Storyboard{ctx: ctx}
	sb.root = os.dir(path)

	if os.exists(path) {
		mut lines := os.read_lines(path) or { panic("UWU I FUCKED UP: ${err}") }
		sb.parse_lines(lines)
	}

	// canvas shit
	sb.background.scale = resolution.global.storyboard_scale
	sb.background.position.x = ((resolution.global.width - resolution.global.storyboard_width) / 2) / resolution.global.storyboard_scale
	sb.background.position.y = ((resolution.global.height - resolution.global.storyboard_height) / 2) / resolution.global.storyboard_scale
	return sb
}

pub fn (mut storyboard Storyboard) parse_lines(lines_ []string) {
	mut current_section := ''
	mut current_sprite := ''
	mut commands := []string{}
	mut variables := map[string]string{}
	mut lines := lines_.clone()
	mut time_took_to_parse := time2.TimeCounter{}
	time_took_to_parse.reset()

	mut time_took_to_load_object := time2.TimeCounter{}
	
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

				// Two spaces is usually loops and idw to deal with that for now
				if line.starts_with('  ') {
					continue
				}
				
				if line.starts_with("Sprite") || line.starts_with("Animation") {
					if current_sprite.len != 0 {
						time_took_to_load_object.reset()
						storyboard.load_sprite(current_sprite, commands)
						println('> Storyboard: Took ${time_took_to_load_object.tick()/1000:.2f}seconds to load ${current_sprite}!')
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

	println('> Storyboard: Took ${time_took_to_parse.tick() / 1000:.2f}seconds to parse storyboard!')
}

//
pub fn (mut storyboard Storyboard) load_sprite(header string, commands []string) {
	items := parse_comma(header)

	mut img_path := os.join_path(storyboard.root, items[3].replace('"', '').trim_space())

	// ??? what
	if !img_path.ends_with('.png') && !img_path.ends_with('.jpg') {
		println('> sus filepath in storyboard: ${img_path}')
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
			textures: [storyboard.ctx.create_image(img_path)] // ez
		}
		sprite.position.x = position.x
		sprite.position.y = position.y
		parse_sprite_commands(mut sprite, commands)

		if sprite.transforms.len > 0 {
			sprite.after_add_transform_reset()
			sprite.base_size.scale(1 / resolution.global.storyboard_scale)
			sprite.size.scale(1 / resolution.global.storyboard_scale)
			storyboard.background.add_sprite( sprite)
		}
		
		// check for stuff that doesnt have scale tranforms
		mut has_been_scaled := false
		for transform in sprite.transforms {
			if transform.typ == .scale || transform.typ == .scale_factor {
				has_been_scaled = true
			}
		}

		if !has_been_scaled {
			sprite.reset_image_size()
			sprite.base_size.scale(1 / resolution.global.storyboard_scale)
			sprite.size.scale(1 / resolution.global.storyboard_scale)
		}
		

		
	}
}

pub fn parse_sprite_commands(mut spr &sprite.Sprite, commands []string) {
	for command in commands {
		mut items := parse_comma(command)

		if items[0] == 'T' || items[0] == 'L' {
			continue // aint fuckin with you
		}

		command_type := items[0]
		easing := easing.get_easing_from_enum(easing.Easing(items[1].i8())) // for now

		mut start_time := items[2].f64()

		if items[3] == '' {
			items[3] = items[2]
		}

		mut end_time := items[3].f64()
		mut arguments := 0

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
		if arguments == 0 { continue }
		
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
				spr.add_transform(
					typ: .fade, 
					easing: easing, 
					time: time2.Time{start_time, end_time},
					before: sections[0],
					after: sections[1]
				)
			}

			'R' {
				spr.add_transform(
					typ: .angle, 
					easing: easing, 
					time: time2.Time{start_time, end_time},
					before: sections[0],
					after: sections[1]
				)
			}

			'S' {
				spr.add_transform(
					typ: .scale_factor, 
					easing: easing, 
					time: time2.Time{start_time, end_time},
					before: sections[0],
					after: sections[1]
				)
			}

			'MX' {
				spr.add_transform(
					typ: .move_x, 
					easing: easing, 
					time: time2.Time{start_time, end_time},
					before: sections[0],
					after: sections[1]
				)
			}

			'MY' {
				spr.add_transform(
					typ: .move_y, 
					easing: easing, 
					time: time2.Time{start_time, end_time},
					before: sections[0],
					after: sections[1]
				)
			}

			'M' {
				spr.add_transform(
					typ: .move, 
					easing: easing, 
					time: time2.Time{start_time, end_time},
					before: sections[0],
					after: sections[1]
				)
			}

			'V' {
				spr.add_transform(
					typ: .scale, 
					easing: easing, 
					time: time2.Time{start_time, end_time},
					before: sections[0],
					after: sections[1]
				)
			}

			'C' {
				spr.add_transform(
					typ: .color, 
					easing: easing, 
					time: time2.Time{start_time, end_time},
					before: sections[0],
					after: sections[1]
				)
			}

			else { println('> Storyboard: Invalid command => ${command_type}') }
		}
	}
}