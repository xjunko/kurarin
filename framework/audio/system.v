module audio

import framework.logging

// Start Bass and shit
fn init() {
	playback_buffer_length := int(100)
	device_buffer_length := int(10)
	update_period := int(5)
	dev_update_period := int(10)

	C.BASS_SetConfig(C.BASS_CONFIG_DEV_NONSTOP, 1)
	C.BASS_SetConfig(C.BASS_CONFIG_VISTA_TRUEPOS, 0)
	C.BASS_SetConfig(C.BASS_CONFIG_BUFFER, playback_buffer_length)
	C.BASS_SetConfig(C.BASS_CONFIG_UPDATEPERIOD, update_period)
	C.BASS_SetConfig(C.BASS_CONFIG_DEV_BUFFER, device_buffer_length)
	C.BASS_SetConfig(C.BASS_CONFIG_DEV_PERIOD, dev_update_period)
	C.BASS_SetConfig(68, 1)

	if C.BASS_Init(-1, 44100, 0, 0, 0) != 0 {
		logging.info("BASS Started!")
	} else {
		logging.error("Failed to start BASS!")
	}
}