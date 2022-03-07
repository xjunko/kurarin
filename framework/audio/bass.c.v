module audio

#flag -I @VMODROOT/audio/bass
#include "bass.h"
#include "bass_fx.h"

// Important bits
fn C.BASS_Init(int, int, int, int, int) int
fn C.BASS_SetConfig(int, int)

// Track
fn C.BASS_StreamCreateFile(int, &char, int, int, int) C.HSTREAM
fn C.BASS_ChannelPlay(C.HSTREAM, int)
fn C.BASS_ChannelSetAttribute(C.HSTREAM, int, f32)
fn C.BASS_ChannelSetPosition(C.HSTREAM, C.QWORD, int)

// Utils
fn C.BASS_SampleGetChannel(C.HSTREAM, int) C.HSTREAM
fn C.BASS_SampleLoad(int, &char, int, int, int, int) C.HSTREAM
fn C.BASS_ChannelSeconds2Bytes(C.HSTREAM, f64) C.QWORD