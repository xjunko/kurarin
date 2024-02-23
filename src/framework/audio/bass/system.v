module bass

import framework.logging
import core.common.settings

pub struct BassMixer {
pub mut:
	master C.HSTREAM
}

pub fn (mut bass_mixer BassMixer) init() {
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

	mut device_id := -1
	mut mixer_flags := C.BASS_MIXER_NONSTOP

	if settings.global.video.record {
		logging.info('BASS in recording mode')
		device_id = 0
		mixer_flags |= C.BASS_SAMPLE_FLOAT | C.BASS_STREAM_DECODE
	}

	if C.BASS_Init(device_id, 48000, 0, 0, 0) != 0 {
		logging.info('BASS Started!')

		// Mixer
		master_mixer := C.BASS_Mixer_StreamCreate(48000, 2, mixer_flags)
		C.BASS_ChannelSetAttribute(master_mixer, C.BASS_ATTRIB_BUFFER, 0)
		C.BASS_ChannelSetDevice(master_mixer, C.BASS_GetDevice())

		C.BASS_ChannelPlay(master_mixer, 0)

		bass_mixer.master = master_mixer
	} else {
		logging.error('Failed to start BASS!')
	}
}
