module beatmap

import os

pub struct Beatmap {
pub mut:
	title  string
	artist string
	audio  string
	bg     string
	file   string
	root   string
}

pub fn (b Beatmap) get_audio() string {
	return os.join_path(b.root, b.audio)
}

pub fn (b Beatmap) get_background() string {
	return os.join_path(b.root, b.bg)
}

pub fn (b Beatmap) get_full_path() string {
	return os.join_path(b.root, b.file)
}

// Parse
pub fn parse_k_v_colon(line string) []string {
	mut items := []string{}

	for item in line.split(':') {
		items << item.trim_space()
	}

	return items
}

pub fn parse_beatmap(path string) Beatmap {
	if !os.exists(path) {
		panic('File did not exists! [${path}]')
	}

	mut beatmap := Beatmap{
		root: os.dir(path)
		file: os.base(path)
	}
	mut category := ''
	mut lines := os.read_lines(path) or { panic('Failed to read beatmap file: ${err}') }

	for line in lines {
		if line.starts_with('//') || line.trim_space().len == 0 {
			continue
		}

		if line.starts_with('[') {
			category = line.trim_space().replace('[', '').replace(']', '')
			continue
		}

		match category {
			'General', 'Metadata' {
				items := parse_k_v_colon(line)

				match items[0] {
					'AudioFilename' { beatmap.audio = items[1] }
					'Title' { beatmap.title = items[1] }
					'Artist' { beatmap.artist = items[1] }
					else {}
				}
			}
			'Events' {
				if beatmap.bg.len == 0 && (line.starts_with('0') || line.starts_with('Sprite')) {
					beatmap.bg = line.split(',')[2].replace('"', '')
				}
			}
			else {}
		}
	}

	return beatmap
}
