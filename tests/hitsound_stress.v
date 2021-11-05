module tests

import time
// import framework.audio
import lib.miniaudio

pub fn stress_test_audio() {
	mut master := miniaudio.make_device()
	mut x := 0

	master.volume(.1)
	// This should atleast play to 5000 without crashing.
	for x < 2000 {
		mut sound := master.add_audio(path: 'assets/skins/default/drum-hitclap2.wav')
		sound.play()

		print('Hitsound played: ${x++} times! \r')
		time.sleep(16 * time.millisecond)
	}
	master.free()
	println('Hitsound test passed!\t')
}