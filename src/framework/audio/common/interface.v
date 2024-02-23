module common

// Structs
pub interface IBackend {
mut:
	// Internal
	init()
	get_required_buffer_size_for_mixer(seconds f64) int
	get_mixer_data(mut buffer []u8)
	// Creation
	new_track(path string) &ITrack
	new_sample(path string) &ISample
}

pub interface ITrack {
mut:
	// Field
	playing bool
	effects AudioEffects
	// Method
	play()
	pause()
	resume()
	set_volume(vol f32)
	set_position(millis f64)
	set_speed(new_speed f64)
	set_pitch(new_pitch f64)
	update(update_time f64)
	get_position() f64
}

pub interface ISample {
mut:
	// Field
	playing bool
	effects AudioEffects
	// Method
	play()
	play_volume(vol f32)
	pause()
	resume()
	set_volume(vol f32)
	set_position(millis f64)
	set_speed(new_speed f64)
	set_pitch(new_pitch f64)
	update(update_time f64)
	get_position() f64
}
