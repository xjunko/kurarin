// Copyright(C) 2019-2021 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
// miniaudio https://github.com/dr-soft/miniaudio @ dbca7a3b (Version 0.10.42)
// is licensed under the unlicense and, are thus, in the public domain.
module c

pub const used_import = 1

// #flag -I ./miniaudio/c // for the wrapper code
#flag -I @VMODROOT/miniaudio
$if linux {
	#flag -lpthread -lm -ldl
}

$if macos {
	#flag -lpthread -lm
}

// Enables FLAC decoding.
#flag -D  DR_FLAC_IMPLEMENTATION
#include "extras/dr_flac.h"

// Enables MP3 decoding.
#flag -D  DR_MP3_IMPLEMENTATION
#include "extras/dr_mp3.h"

// Enables WAV decoding.
#flag -D  DR_WAV_IMPLEMENTATION
#include "extras/dr_wav.h"

$if debug {
	#flag -D MA_DEBUG_OUTPUT
	#flag -D MA_LOG_LEVEL_VERBOSE
}

// #flag -D MA_NO_PULSEAUDIO
#flag -D MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"
// #include "../miniaudio_wrap.h" // for wrapper code
