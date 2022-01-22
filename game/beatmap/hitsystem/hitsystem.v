module hitsystem

/* 
	sike! theres no hitsystem in here, i want to add combo counter so yea
	thats why this exists....

	maybe ill add actual hitsystem but for now thisll do :trollface:
*/

import os

const (
	binary_path = os.join_path(@VMODROOT, "assets/binary/oppai")
	update_rate = f64(200.0)
)

pub struct HitSystem {
	pub mut:
		path  	   string
		combo 	   int
		pp         f64
		last_time  f64
		last_delta f64
}

pub fn (mut hitsystem HitSystem) update_map_path(p string) {
	hitsystem.path = p
}

pub fn (mut hitsystem HitSystem) increment_combo() {
	hitsystem.combo++
}

pub fn (mut hitsystem HitSystem) update(time f64) {
	// Check if reach delta
	hitsystem.last_delta += (time - hitsystem.last_time)

	if hitsystem.last_delta >= update_rate {
		hitsystem.last_delta -= update_rate

		// This is not the greatest way to do it, I tried to bind the C library with V, but it doesnt work for some reason...
		mut result := os.execute('${binary_path} "${hitsystem.path}" ${hitsystem.combo}x').output.split("\n")
		
		if result.len == 14 { // Only parse when list length matched
			hitsystem.pp = result[11].split(" ")[0].f64()
		}

		unsafe {
			result.free()
		}
	}

	// Done
	hitsystem.last_time = time
}

pub fn get_hitsystem() &HitSystem {
	mut hitsystem := &HitSystem{}

	return hitsystem
}