module beatmap

import os
import framework.logging

const c_hard_limit = 100

pub struct BeatmapContainer {
pub mut:
	info     BeatmapMetadataInfo
	versions []Beatmap
}

pub struct BeatmapManager {
mut:
	root string
pub mut:
	beatmaps []BeatmapContainer
}

pub fn (mut manager BeatmapManager) load() {
	logging.info('[${@METHOD}] Loading beatmaps in `${manager.root}`')

	for i, folder in os.glob(os.join_path(manager.root, '*')) or { [''] } {
		if os.is_dir(folder) {
			mut container := BeatmapContainer{}

			for file in os.glob(os.join_path(folder, '*.osu')) or { [''] } {
				current_bm_version := parse_beatmap(file, true)

				if container.info.title.len == 0 && container.info.artist.len == 0 {
					container.info = current_bm_version.metadata
				}

				container.versions << current_bm_version
			}

			container.versions.sort(a.metadata.id < b.metadata.id)

			manager.beatmaps << container
		}

		if i > beatmap.c_hard_limit {
			break
		}
	}

	logging.info('[${@METHOD}] Found ${manager.beatmaps.len} beatmaps.')
}

pub fn make_manager(root string) &BeatmapManager {
	mut manager := &BeatmapManager{
		root: root
	}

	manager.load()

	return manager
}

// fn init() {
// 	make_manager('/run/media/junko/2nd/Projects/dementia/assets/osu/maps/')
// }
