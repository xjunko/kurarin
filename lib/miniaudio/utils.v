// Copyright(C) 2019 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
// miniaudio (https://github.com/dr-soft/miniaudio)
// is licensed under the unlicense and, are thus, in the publiic domain.
module miniaudio

fn translate_error_code(code int) string {
	match code {
		C.MA_SUCCESS {
			return 'SUCCESS'
		}
		// General errors.
		C.MA_ERROR {
			return 'MA_ERROR'
		} // A generic error.
		C.MA_INVALID_ARGS {
			return 'MA_INVALID_ARGS'
		}
		C.MA_INVALID_OPERATION {
			return 'MA_INVALID_OPERATION'
		}
		C.MA_OUT_OF_MEMORY {
			return 'MA_OUT_OF_MEMORY'
		}
		C.MA_ACCESS_DENIED {
			return 'MA_ACCESS_DENIED'
		}
		C.MA_TOO_LARGE {
			return 'MA_TOO_LARGE'
		}
		C.MA_TIMEOUT {
			return 'MA_TIMEOUT'
		}
		// General miniaudio-specific errors.
		C.MA_FORMAT_NOT_SUPPORTED {
			return 'MA_FORMAT_NOT_SUPPORTED'
		}
		C.MA_DEVICE_TYPE_NOT_SUPPORTED {
			return 'MA_DEVICE_TYPE_NOT_SUPPORTED'
		}
		C.MA_SHARE_MODE_NOT_SUPPORTED {
			return 'MA_SHARE_MODE_NOT_SUPPORTED'
		}
		C.MA_NO_BACKEND {
			return 'MA_NO_BACKEND'
		}
		C.MA_NO_DEVICE {
			return 'MA_NO_DEVICE'
		}
		C.MA_API_NOT_FOUND {
			return 'MA_API_NOT_FOUND'
		}
		C.MA_INVALID_DEVICE_CONFIG {
			return 'MA_INVALID_DEVICE_CONFIG'
		}
		// State errors.
		C.MA_DEVICE_BUSY {
			return 'MA_DEVICE_BUSY'
		}
		C.MA_DEVICE_NOT_INITIALIZED {
			return 'MA_DEVICE_NOT_INITIALIZED'
		}
		C.MA_DEVICE_NOT_STARTED {
			return 'MA_DEVICE_NOT_STARTED'
		}
		C.MA_DEVICE_UNAVAILABLE {
			return 'MA_DEVICE_UNAVAILABLE'
		}
		// Operation errors.
		C.MA_FAILED_TO_MAP_DEVICE_BUFFER {
			return 'MA_FAILED_TO_MAP_DEVICE_BUFFER'
		}
		C.MA_FAILED_TO_UNMAP_DEVICE_BUFFER {
			return 'MA_FAILED_TO_UNMAP_DEVICE_BUFFER'
		}
		C.MA_FAILED_TO_INIT_BACKEND {
			return 'MA_FAILED_TO_INIT_BACKEND '
		}
		C.MA_FAILED_TO_READ_DATA_FROM_CLIENT {
			return 'MA_FAILED_TO_READ_DATA_FROM_CLIENT'
		}
		C.MA_FAILED_TO_READ_DATA_FROM_DEVICE {
			return 'MA_FAILED_TO_READ_DATA_FROM_DEVICE'
		}
		C.MA_FAILED_TO_SEND_DATA_TO_CLIENT {
			return 'MA_FAILED_TO_SEND_DATA_TO_CLIENT'
		}
		C.MA_FAILED_TO_SEND_DATA_TO_DEVICE {
			return 'MA_FAILED_TO_SEND_DATA_TO_DEVICE'
		}
		C.MA_FAILED_TO_OPEN_BACKEND_DEVICE {
			return 'MA_FAILED_TO_OPEN_BACKEND_DEVICE'
		}
		C.MA_FAILED_TO_START_BACKEND_DEVICE {
			return 'MA_FAILED_TO_START_BACKEND_DEVICE'
		}
		C.MA_FAILED_TO_STOP_BACKEND_DEVICE {
			return 'MA_FAILED_TO_STOP_BACKEND_DEVICE'
		}
		C.MA_FAILED_TO_CONFIGURE_BACKEND_DEVICE {
			return 'MA_FAILED_TO_CONFIGURE_BACKEND_DEVICE'
		}
		C.MA_FAILED_TO_CREATE_MUTEX {
			return 'MA_FAILED_TO_CREATE_MUTEX'
		}
		C.MA_FAILED_TO_CREATE_EVENT {
			return 'MA_FAILED_TO_CREATE_EVENT'
		}
		C.MA_FAILED_TO_CREATE_THREAD {
			return 'MA_FAILED_TO_CREATE_THREAD'
		}
		else {
			return 'UNKNOWN'
		}
	}
}
