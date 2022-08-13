module old_gui

import library.gg

import framework.logging
import framework.math.time
import framework.math.vector

import core.osu.cursor
import core.osu.ruleset

pub fn (mut window Window) key_down(key gg.KeyCode, _ gg.Modifier, _ voidptr) {
	if window.task == .menu {
		// Change current playing song
		if key == .right { window.next_song() }
		if key == .left { window.previous_song() }	


		// Trigger Menu/Changing scene
		if key == .p && !window.menu_triggered {
			window.menu_triggered = true
			return // Return here, dont want to trigger the stmt below.
		}

		if key == .p && window.menu_triggered {
			// Hide logo and stuff
			window.logo_s.add_transform(typ: .fade, time: time.Time{time.global.time, time.global.time + 100}, before: [0.0])
			
			for mut button in window.menu_buttons {
				button.add_transform(typ: .fade, time: time.Time{time.global.time, time.global.time + 100}, before: [0.0])
			}
			
			// Move visualizer
			window.visualizer.update_logo(vector.Vector2{-720.0, 0}, vector.Vector2{720,720})

			// Unhide menu element
			for mut elem in window.list_beatmap_s {
				elem.add_transform(typ: .fade, time: time.Time{time.global.time, time.global.time + 100}, before: [255.0])
			}

			// Change to list scene
			window.task = .list
		}

		// Go back menu
		if key == .escape {
			window.menu_triggered = false
		}
		
		// Debug
		if key == .q {
			if window.current != voidptr(0) {
				logging.info("Loading: ${window.current.metadata.title}")

				// Fake loading.
				window.task = .loading_beatmap
				
				// Load stuff in another thread
				go fn (mut window Window){
					// Load full beatmap
					window.current = window.current.load_full_beatmap()
					window.current.bind_context(mut window.ctx)
					window.current.reset()

					// Make auto
					// TODO: Player mode
					window.auto = cursor.make_auto_cursor(mut window.ctx, window.current.objects)
					window.players << unsafe { window.auto.cursor }

					// Make ruleset
					window.ruleset = ruleset.new_ruleset(mut window.current, mut window.players)

					// Stop audio n shit
					window.audio.pause()
					window.audio = voidptr(0)

					// Relative time
					window.start_playing_at = time.global.time

					// Play
					window.task = .playing
				}(mut window)
			}
		}
	} 

	// TEST: just a test, this is a test.
	if window.task == .playing {
		if key == .escape {
			unsafe {
				// FIXME: free memory
				// window.ruleset.free()
				window.ruleset = voidptr(0)
				// window.auto.free()
				window.auto = voidptr(0)
				window.players.clear()
				window.audio.pause()
			}
			
			window.task = .menu
		}
	}

	if window.task == .list {
		if key == .right { window.next_song() }
		if key == .left { window.previous_song() }	
	}
}