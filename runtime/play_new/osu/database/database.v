module database

import core.osu.beatmap

pub struct OsuDatabase {
	pub mut:
		beatmaps []&beatmap.Beatmap
}

pub fn (mut database OsuDatabase) add_beatmap(mut beatmap &beatmap.Beatmap) {
	database.beatmaps << beatmap
}

pub fn (mut database OsuDatabase) get_random_beatmap() &beatmap.Beatmap {
	// TODO: make this random lmao
	return database.beatmaps[0]
}