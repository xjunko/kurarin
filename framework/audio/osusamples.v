module audio

const (
	samples = [
		["normal-hitnormal", "soft-hitnormal", "drum-hitnormal"],
		["normal-hitwhistle", "soft-hitwhistle", "drum-hitwhistle"],
		["normal-hitfinish", "soft-hitfinish", "drum-hitfinish"],
		["normal-hitclap", "soft-hitclap", "drum-hitclap"]
	]
)

pub fn (mut audio AudioController) play_osu_sample(sample int, sample_set int) {
	audio.add_audio_and_play(path: 'assets/skins/default/${samples[0][sample_set - 1]}.wav')

	if (sample & 2) > 0 {
		audio.add_audio_and_play(path: 'assets/skins/default/${samples[1][sample_set - 1]}.wav')
	}
	if (sample & 4) > 0 {
		audio.add_audio_and_play(path: 'assets/skins/default/${samples[2][sample_set - 1]}.wav')
	}
	if (sample & 8) > 0 {
		audio.add_audio_and_play(path: 'assets/skins/default/${samples[3][sample_set - 1]}.wav')
	}
}
