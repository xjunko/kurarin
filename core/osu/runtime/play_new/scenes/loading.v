module scenes

import os
// import osu

pub enum LoadingStatus {
	nothing
	loading
	done
}

pub struct LoadingScene {
	Scene

	pub mut:
		status LoadingStatus
}

pub fn (mut scene LoadingScene) update(time f64) {
	if scene.status != .loading {
		scene.status = .loading

		// Start loading beatmap (in another thread :ooo)
		go fn (mut scene LoadingScene) {
			beatmaps_folder := r"/run/media/junko/2nd/Games/osu!/Songs/"
			// mut beatmap_counter := int(0)

			if beatmaps := os.glob(os.join_path(beatmaps_folder, "*")) {
				for beatmap_path in beatmaps {
					println(beatmap_path)
				}
			}

			// Done, change scene status.
			scene.status = .done

		}(mut scene)
	}
}