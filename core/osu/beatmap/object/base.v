module object

// Learned my lesson so im just gonna do danser's method
// Inherit HitObject instead of relying on uninitialized HitCircle (my old code does this, pretty fucked tbh)
import framework.graphic.sprite

import framework.math.time
import framework.math.vector

import core.osu.beatmap.timing
import core.osu.beatmap.difficulty

pub const (
	used_imports = true
)

pub interface IHitObject {
	mut:
		id   int
		diff difficulty.Difficulty

		time         time.Time
		position     vector.Vector2
		end_position vector.Vector2

		raw_position     vector.Vector2
		raw_end_position vector.Vector2

		stack_offset vector.Vector2
		stack_index  int

		color        []f64
		color_offset int

		is_slider   bool
		is_spinner  bool

		done        bool
		
		draw(sprite.CommonSpriteArgument)
		update(f64) bool
		post_update(f64)
		set_timing(timing.Timings)
		set_difficulty(difficulty.Difficulty)

		get_start_time() f64
		get_end_time() f64
		get_duration() f64

		get_start_position() vector.Vector2
		get_end_position() vector.Vector2

		get_id() int
		set_id(int)

		is_new_combo() bool
		set_new_combo(bool)
		set_combo_number(int)

		set_boost_level(f32)
}

pub struct HitSoundInfo {
	pub mut:
		sample_set   int
		addition_set int
		custom_index int
		custom_vol   f64
}

pub struct HitObject {
	pub mut:
		id   int
		diff difficulty.Difficulty

		time         time.Time
		position     vector.Vector2
		end_position vector.Vector2

		raw_position     vector.Vector2
		raw_end_position vector.Vector2

		stack_offset vector.Vector2
		stack_index  int

		new_combo    bool
		combo_number int
		color        []f64 = [255.0, 255.0, 255.0]
		color_offset int

		// Types
		is_slider   bool
		is_spinner  bool

		// Internal
		done        bool
		data        []string
		hitsound    HitSoundInfo
		music_boost f32 = f32(1.0)
}

// pub fn (mut hitobject HitObject) draw(arg sprite.CommonSpriteArgument) // :trolldecai: looks like i need to uncomment one of these (interface methods) for the code to compile bruh moment
pub fn (mut hitobject HitObject) update(time f64) bool { return true }
pub fn (mut hitobject HitObject) post_update(time f64) {}
pub fn (mut hitobject HitObject) set_timing(t timing.Timings) {}
pub fn (mut hitobject HitObject) set_difficulty(d difficulty.Difficulty) {}
pub fn (hitobject &HitObject) get_start_time() f64 { return hitobject.time.start }
pub fn (hitobject &HitObject) get_end_time() f64 { return hitobject.time.end }
pub fn (hitobject &HitObject) get_duration() f64 { return hitobject.time.duration() }
pub fn (hitobject &HitObject) get_start_position() vector.Vector2 { return hitobject.position }
pub fn (hitobject &HitObject) get_end_position() vector.Vector2 { return hitobject.end_position }
pub fn (hitobject &HitObject) get_id() int { return hitobject.id }
pub fn (mut hitobject HitObject) set_id(id int) { hitobject.id = id }
pub fn (mut hitobject HitObject) set_combo_number(n int) { hitobject.combo_number = n }
pub fn (hitobject &HitObject) is_new_combo() bool { return hitobject.new_combo }
pub fn (mut hitobject HitObject) set_new_combo(b bool) { hitobject.new_combo = b }
pub fn (mut hitobject HitObject) set_boost_level(boost f32) { hitobject.music_boost = boost}



// Utils
pub fn common_parse(items []string, extra_index int) &HitObject {
	position := vector.Vector2{
		items[0].f64()
		items[1].f64()
	}
	time := time.Time{
		items[2].f64(),
		items[2].f64()
	}
	object_type := items[3].int()

	mut hitobject := &HitObject{
		data: items,
		id: -1
		position: position,
		raw_position: position,
		end_position: position,
		raw_end_position: position,
		time: time,
		new_combo: (object_type & new_combo) == 4,
		color_offset: (object_type >> new_combo) & 7,
		is_slider: (object_type & slider) > 0,
		is_spinner: (object_type & spinner) > 0
	}

	// Extra data
	if extra_index < items.len && items[extra_index].len > 0 {
		extras := items[extra_index].split(":")
		
		if extras.len <= 1 {
			return hitobject // This map is probably retarded.
		}

		hitobject.hitsound.sample_set = extras[0].int()
		hitobject.hitsound.addition_set = extras[1].int()

		if extras.len > 2 {
			hitobject.hitsound.custom_index = extras[2].int()
		}

		if extras.len > 3 {
			hitobject.hitsound.custom_vol = extras[0].f64() / 100.0
		}
	}
	
	return hitobject
}