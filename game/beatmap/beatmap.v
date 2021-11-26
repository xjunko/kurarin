module beatmap

import os
import math
import lib.gg
import object

import framework.graphic.sprite
import framework.math.time as time2

import game.math.difficulty
import game.math.timing
import game.math.resolution
import game.storyboard

pub fn parse_common_struct_generic_bullshit<T>(mut strct T, name string, value string) {
	$for field in T.fields {
		if name == field.name {
			$if field.typ is string {
				strct.$(field.name) = value
			} $else $if field.typ is int {
				strct.$(field.name) = value.int()
			} $else $if field.typ is f32 {
				strct.$(field.name) = value.f32()
			} $else $if field.typ is f64 {
				strct.$(field.name) = value.f64()
			} $else $if field.typ is bool {
				strct.$(field.name) = value == '1'
			} $else {
				panic("> ayo bro unsupported type, ill go crashy crashy now.")
			}
		}
	}
}

pub struct BeatmapGeneralInfo {
	pub mut:
		audiofilename string
		audioleadin   int
		previewtime   int
		countdown     bool
		stackleniency f32
		mode          int
		letterboxinbreaks bool
		widescreenstoryboard bool
}

pub struct Beatmap {
	pub mut:
		general    		BeatmapGeneralInfo
		difficulty 		difficulty.DifficultyInfo
		difficulty_math difficulty.Difficulty
		timing          timing.TimingPoint
		objects    		[]object.IHitObject
		ready      		bool

		//
		colors          [][]f64
		storyboard      &storyboard.Storyboard = voidptr(0)


		// fs
		root     string
		filename string
		background 		  string
		background_sprite &sprite.Sprite = &sprite.Sprite{}

		// temp
		sb_extra []string
}

// property
pub fn (beatmap Beatmap) get_audio_file() string {
	return os.join_path(beatmap.root, beatmap.general.audiofilename)
}

pub fn (beatmap Beatmap) get_bg_file() string {
	return os.join_path(beatmap.root, beatmap.background)
}

pub fn (beatmap Beatmap) get_storyboard_file() ?string {
	// TODO: maybe make this read difficulty storyboard if theres any
	files := os.glob(os.join_path(beatmap.root, "*.osb")) or { return none }

	if files.len > 0 {
		return os.join_path(beatmap.root, files[0])
	}

	return none
}


// checks and stuff
pub fn (mut beatmap Beatmap) draw(ctx &gg.Context, time f64) {
	if !beatmap.ready { return }

	for mut object in beatmap.objects {
		object.draw(ctx, time)
	}
}

pub fn (mut beatmap Beatmap) initialize_sprite_component(mut ctx &gg.Context) {
	// load bg
	beatmap.background_sprite = &sprite.Sprite{
		textures: [ctx.create_image(beatmap.get_bg_file())],
		always_visible: true
	}

	bg_height := f64(beatmap.background_sprite.image().height)
	ratio := f64(f64(resolution.global.height) / f64(bg_height)) * 1.1 // epic trolling
	beatmap.background_sprite.add_transform(typ: .move, time: time2.Time{0, 1}, before: [f64(resolution.global.width/2), f64(resolution.global.height/2)])
	beatmap.background_sprite.add_transform(typ: .scale_factor, time: time2.Time{0, 1}, before: [ratio])

	// fade in
	beatmap.background_sprite.add_transform(typ: .fade, time: time2.Time{beatmap.objects[0].time.start - 500, beatmap.objects[0].time.start}, before: [f64(0)], after: [f64(100)])
	// fade out
	beatmap.background_sprite.add_transform(typ: .fade, time: time2.Time{beatmap.objects[beatmap.objects.len - 1].time.end + 1000, beatmap.objects[beatmap.objects.len - 1].time.end + 4000}, before: [f64(100)], after: [f64(0)])
	//
	beatmap.background_sprite.after_add_transform_reset()

	// stack
	beatmap.process_stack_position()

	// load hitobject shit
	for i in 0 .. beatmap.objects.len {
		beatmap.objects[i].initialize_object(mut ctx, beatmap.objects[int(math.max(0, i - 1))])
	}
	
	// Sort from last circle to first
	// This way itll render correctly without me fucking with z index
	// beatmap.objects.sort(a.time.end > b.time.end) // ok nvm this is gay

	beatmap.ready = true
}

// Storyboard
pub fn (mut beatmap Beatmap) setup_storyboard(mut ctx &gg.Context) {
	storyboard_path := beatmap.get_storyboard_file() or { '' }
	println("> Storyboard: Setup! Path is ${storyboard_path}")
	
	//
	beatmap.storyboard = storyboard.parse_storyboard(mut ctx, storyboard_path)
	beatmap.storyboard.parse_lines(beatmap.sb_extra)

	// Canvas position (temporary (or maybe permanent since im lazy) till i figure out whats wrong with the canvas position)
	beatmap.storyboard.background.position.x = 105
	println("> Storyboard: Done!")
}