module window

// import lib.gg
// import time as timelib

// import framework.graphic.sprite
// import framework.math.time as time2
// import framework.math.easing
// import game.auto



// pub struct AddPlayerArg {
// 	name string = 'Auto'
// 	events []auto.ReplayEvent

// }

// pub fn (mut window GameWindow) add_auto_player(args AddPlayerArg) {
// 	/*
// 	if args.events.len == 0 {
// 		return
// 	}

// 	// Turn it into a sprite object
// 	mut player_sprite := &sprite.Sprite{
// 		textures: [gg.get_texture_from_skin('cursor')],
// 		always_visible: true,
// 		// skip_offset: true // PlayerMode
// 	}

	
// 	mut last_event := args.events[0]
// 	for event in args.events {
// 		player_sprite.add_transform(
// 			typ: .move,
// 			easing: easing.quad_out,
// 			time: time2.Time{last_event.time.end, event.time.start},
// 			before: [last_event.position.x, last_event.position.y],
// 			after: [event.position.x, event.position.y]
// 		)
// 		last_event = event
// 	}
	

// 	player_sprite.after_add_transform_reset()
// 	window.auto_repr = player_sprite

// 	// add into canvas then listen to it
// 	window.game_canvas.add_drawable(player_sprite)

	
// 	go fn (mut window &GameWindow, player_sprite &sprite.Sprite, events []auto.ReplayEvent) {
// 		mut event_index := 0
// 		for event_index < events.len {
// 			if window.game_time.time >= events[event_index].time.start {
// 				if events[event_index].key != 0 {
// 					window.logic.player.left_key = true
// 				}

// 				// stop holdin the key and go on to the next event
// 				if window.game_time.time >= events[event_index].time.start + 32 {
// 					window.logic.player.left_key = false
// 					event_index++
// 				}	
// 			}

// 			timelib.sleep(1 * timelib.millisecond)
// 		}
// 	}(mut window, player_sprite, args.events)
// 	*/
// }