module skin

import gg
import os

/*
Note(s):
		* CPOL or """Modern"" skins tend to have retarded `skin.ini` file so beware of that.
*/

// https://osu.ppy.sh/wiki/en/Skinning/skin.ini#[general]
pub struct SkinMetadata {
pub mut:
	name   string @[Name]
	author string @[Author]

	version             f64 @[Version]
	animation_framerate f64 @[AnimationFramerate]
	// Cursor
	cursor_centre bool @[CursorCentre]
	cursor_expand bool @[CursorExpand]
	cursor_rotate bool @[CursorRotate]
	// Sliders
	slider_ball_tint      bool     @[AllowSliderBallTint]
	slider_ball_flip      bool     @[SliderBallFlip]
	slider_ball           gg.Color @[SliderBall]
	slider_border         gg.Color @[SliderBorder]
	slider_track_override gg.Color @[SliderTrackOverride]
	// HitCircle
	hit_circle_prefix  string @[HitCirclePrefix]
	hit_circle_overlap f64    @[HitCircleOverlap]
	// Score
	score_prefix  string @[ScorePrefix]
	score_overlap f64    @[ScoreOverlap]
	// Combo
	combo_prefix  string     @[ComboPrefix]
	combo_overlap f64        @[ComboOverlap]
	combo_colors  []gg.Color
}

// get_frames_time returns positive integer or 1000/frames to make it play all frames of the animation in one second
pub fn (mut meta SkinMetadata) get_frame_time(frames int) f64 {
	if meta.animation_framerate > 0 {
		return 1000.0 / meta.animation_framerate
	}

	return 1000.0 / f64(frames)
}

// Parse
fn load_skin_info(path_to_skin string) &SkinMetadata {
	lines := os.read_lines(os.join_path(path_to_skin, 'skin.ini')) or { []string{} }

	if lines.len == 0 {
		println('[${@METHOD}] Nothing found in the `skin.ini` file.')
	}

	mut skin_info := get_default_skin_info()
	mut combo_colors := []gg.Color{}

	for line in lines {
		items := tokenize_ini_format_line(line, ':')

		if items.len == 0 {
			continue
		}

		// Combo color
		if items[0].starts_with('Combo') {
			// TODO: Does index matter in this case?
			// index := items[0].split('Combo')[1].int()
			colors := items[1].split(',').map(it.u8())

			if colors.len < 3 {
				continue // Color is borked.
			}

			combo_colors << gg.Color{colors[0], colors[1], colors[2], 255}

			continue
		}

		general_skin_parser[SkinMetadata](mut skin_info, items[0], items[1])
	}

	skin_info.combo_colors = combo_colors

	return skin_info
}

// Utils
fn tokenize_ini_format_line(_line string, delimiter string) []string {
	mut line := _line.trim_space()

	if line.starts_with('//') || !line.contains(delimiter) {
		return []string{}
	}

	return line.split(delimiter).map(it.trim_space())
}

fn get_default_skin_info() &SkinMetadata {
	return &SkinMetadata{
		name: ''
		author: ''
		version: 2.7
		animation_framerate: -1
		cursor_centre: true
		cursor_expand: true
		cursor_rotate: true
		slider_ball_tint: false
		slider_ball_flip: false
		slider_border: gg.Color{255, 255, 255, 255}
		slider_track_override: gg.Color{255, 255, 255, 255}
		hit_circle_prefix: 'default'
		hit_circle_overlap: -2
		score_prefix: 'score'
		score_overlap: 0
		combo_prefix: 'score'
		combo_overlap: 0
	}
}

pub fn general_skin_parser[T](mut cls T, name string, value string) {
	$for field in T.fields {
		// No attrs defined       // Attrs Defined										// No _SKIP defined in attrs
		if (field.name == name || (field.attrs.len > 0 && field.attrs[0] == name))
			&& !field.attrs.contains('_SKIP') {
			// This is ugly but itll do for now
			$if field.typ is string {
				cls.$(field.name) = value
			} $else $if field.typ is int {
				cls.$(field.name) = value.int()
			} $else $if field.typ is f32 {
				cls.$(field.name) = value.f32()
			} $else $if field.typ is i64 {
				cls.$(field.name) = value.i64()
			} $else $if field.typ is f64 {
				cls.$(field.name) = value.f64()
			} $else $if field.typ is bool {
				cls.$(field.name) = value == '1'
			} $else $if field.typ is gg.Color {
				items := value.split(',').map(it.split('//')[0]).map(it.trim_space()).map(u8(it.int()))
				cls.$(field.name) = gg.Color{items[0], items[1], items[2], 255}
			} $else {
				panic('Type not supported: ${field.typ}')
			}
		}
	}
}

fn main() {
	skin := load_skin_info('/run/media/junko/2nd/Games/osu!/Skins/- # Rafis 2k18 [1.1] (CK FULL)/skin.ini')
	println(skin)
}
