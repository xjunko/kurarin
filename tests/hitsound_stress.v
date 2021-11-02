module tests

import time
// import framework.audio
import lib.miniaudio

pub fn stress_test_audio() {
	mut master := miniaudio.device()
	mut x := 0

	// This should atleast play to 5000 without crashing.
	for x < 5000 {
		mut sound := miniaudio.sound(filename: 'assets/skins/default/drum-hitclap2.wav')
		master.add('${x}.audio', sound)
		sound.volume(.1)
		sound.play()
		print('Hitsound played: ${x++} times! \r')
		time.sleep(16 * time.millisecond)
	}
	println('Hitsound test passed!\t')
}