// Copyright(C) 2019 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
// miniaudio (https://github.com/dr-soft/miniaudio)
// is licensed under the unlicense and, are thus, in the public domain.
module miniaudio

// #flag -I ./miniaudio/c // for the wrapper code
#flag -I @VROOT/c/miniaudio
$if linux {
	#flag -lpthread -lm -ldl
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
/*
$if debug {
    #flag -D MA_DEBUG_OUTPUT
    #flag -D MA_LOG_LEVEL_VERBOSE
}
*/

// #flag -D MA_NO_PULSEAUDIO
#flag -D MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"
// #include "../miniaudio_wrap.h" // for wrapper code
// ma_uint32 read_and_mix_pcm_frames_f32(ma_decoder* pDecoder, float* pOutputF32, ma_uint32 frameCount)
// fn C.read_and_mix_pcm_frames_f32(pDecoder &C.ma_decoder, pOutputF32 voidptr, frameCount u32) u32
// #define macros
// fn C.ma_countof(x voidptr) int
// fn C.ma_countof(obj []f32) int
enum DeviceType {
	playback = 1 // ma_device_type_playback
	capture = 2 // ma_device_type_capture
	duplex = 3 // ma_device_type_playback | ma_device_type_capture, /* 3 */
	loopback = 4 // ma_device_type_loopback
}

enum Format {
	unknown = 0 // ma_format_unknown
	u8 = 1 // ma_format_u8
	s16 = 2 // ma_format_s16
	s24 = 3 // ma_format_s24
	s32 = 4 // ma_format_s32
	f32 = 5 // ma_format_f32
	count // ma_format_count
}

struct C.ma_pcm_converter {}

[heap]
struct C.ma_decoder {
	outputFormat     int // Format //C.ma_format
	outputChannels   u32 // C.ma_uint32
	outputSampleRate u32 // C.ma_uint32
}

struct C.playback {
mut:
	format   int // Format //int //C.ma_format
	channels u32 // C.ma_uint32
	// channelMap [32 /*C.MA_MAX_CHANNELS*/ ]ma_channel
}

[typedef]
struct C.ma_device {
mut:
	pUserData voidptr
	playback  C.playback
}

[typedef]
struct C.ma_context {
mut:
	logCallback voidptr // C.ma_log_proc
}

[typedef]
struct C.ma_context_config {
mut:
	logCallback voidptr // C.ma_log_proc
}

[typedef]
struct C.ma_mutex {}

[typedef]
struct C.ma_decoder_config {
	outputFormat     int // Format //C.ma_format
	outputChannels   u32 // C.ma_uint32
	outputSampleRate u32 // C.ma_uint32
}

[typedef]
struct C.ma_device_config {
mut:
	deviceType               C.ma_device_type
	sampleRate               u32 // C.ma_uint32
	bufferSizeInFrames       u32 // C.ma_uint32
	bufferSizeInMilliseconds u32 // C.ma_uint32
	periods                  u32 // C.ma_uint32
	performanceProfile       C.ma_performance_profile
	noPreZeroedOutputBuffer  C.ma_bool32
	noClip                   C.ma_bool32
	dataCallback             voidptr // C.ma_device_callback_proc
	stopCallback             voidptr // C.ma_stop_proc
	pUserData                voidptr
	playback                 C.playback
}

// ma_context
fn C.ma_context_config_init() C.ma_context_config

// ma_result ma_context_init(const ma_backend backends[], ma_uint32 backendCount, const ma_context_config* pConfig, ma_context* pContext);
fn C.ma_context_init(backends []C.ma_backend, backendCount u32, p_config &C.ma_context_config, p_context &C.ma_context) C.ma_result

// ma_result ma_context_uninit(ma_context* pContext);
fn C.ma_context_uninit(p_context &C.ma_context) C.ma_result

// ma_decoder
// ma_result ma_decoder_uninit(ma_decoder* pDecoder);
fn C.ma_decoder_uninit(decoder &C.ma_decoder) C.ma_result

// ma_result ma_decoder_init_file(const char* pFilePath, const ma_decoder_config* pConfig, ma_decoder* pDecoder);
fn C.ma_decoder_init_file(filepath &char, decoder_config &C.ma_decoder_config, decoder &C.ma_decoder) C.ma_result

// ma_result ma_decoder_init_memory(const void* pData, size_t dataSize, const ma_decoder_config* pConfig, ma_decoder* pDecoder);
fn C.ma_decoder_init_memory(data voidptr, len u64, decoder_config &C.ma_decoder_config, decoder &C.ma_decoder) C.ma_result

fn C.ma_decoder_get_length_in_pcm_frames(pDecoder &C.ma_decoder) i64

// ma_uint64 ma_decoder_read_pcm_frames(ma_decoder* pDecoder, void* pFramesOut, ma_uint64 frameCount);
fn C.ma_decoder_read_pcm_frames(pDecoder &C.ma_decoder, pFramesOut voidptr, frameIndex u64) u64

// ma_result ma_decoder_seek_to_pcm_frame(ma_decoder* pDecoder, ma_uint64 frameIndex);
fn C.ma_decoder_seek_to_pcm_frame(pDecoder &C.ma_decoder, frameIndex u64) C.ma_result

// ma_decoder_config
// ma_decoder_config ma_decoder_config_init(ma_format outputFormat, ma_uint32 outputChannels, ma_uint32 outputSampleRate);
fn C.ma_decoder_config_init(outputFormat int, outputChannels u32, outputSampleRate u32) C.ma_decoder_config

// ma_device
// ma_device_config ma_device_config_init(ma_device_type deviceType);
fn C.ma_device_config_init(device_type DeviceType) C.ma_device_config

// ma_result ma_device_init(ma_context* pContext, const ma_device_config* pConfig, ma_device* pDevice);
fn C.ma_device_init(context &C.ma_context, config &C.ma_device_config, device &C.ma_device) C.ma_result

// ma_result ma_device_start(ma_device* pDevice);
fn C.ma_device_start(device &C.ma_device) C.ma_result

fn C.ma_device_is_started(device &C.ma_device) bool

// ma_result ma_device_stop(ma_device* pDevice);
fn C.ma_device_stop(device &C.ma_device) C.ma_result

// void ma_device_uninit(ma_device* pDevice)
fn C.ma_device_uninit(device &C.ma_device)

// ma_decoder
// ma_result ma_mutex_init(ma_context* pContext, ma_mutex* pMutex);
fn C.ma_mutex_init(p_context &C.ma_context, p_mutex &C.ma_mutex) C.ma_result

// void ma_mutex_uninit(ma_mutex* pMutex);
fn C.ma_mutex_uninit(p_mutex &C.ma_mutex)

// void ma_mutex_lock(ma_mutex* pMutex);
fn C.ma_mutex_lock(p_mutex &C.ma_mutex)

// void ma_mutex_unlock(ma_mutex* pMutex);
fn C.ma_mutex_unlock(p_mutex &C.ma_mutex)

// Misc
// ma_uint32 ma_get_bytes_per_sample(ma_format format);
fn C.ma_get_bytes_per_sample(format Format) u32
