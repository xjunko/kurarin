module lzma

import dl
import os

type XzDecode = fn (&u8, u32, &u8, &u32) bool

pub fn get_lzma_function() ?XzDecode {
	mut lzma_object := dl.open_opt("${@VMODROOT}/lzma.so", dl.rtld_lazy) ?
	lzma_xz_decode := XzDecode(dl.sym_opt(lzma_object, "XzDecode") ?)

	return lzma_xz_decode
}

pub fn decode_lzma(data []u8) string {
	xz_decode := get_lzma_function() or { panic("[lzma] I fucked up.") }

	fake_output_buffer := []&u8{}
	output_length := u32(0)

	unsafe {
		result := xz_decode(&data[0], u32(data.len), fake_output_buffer.data, &output_length)

		// Failed
		if !result {
			return ""
		}
		
		output_buffer := malloc(output_length)
		xz_decode(&data[0], u32(data.len), output_buffer, &output_length)

		return cstring_to_vstring(output_buffer)	
	}

	// free stuff
	unsafe {
		free(xz_decode)
		fake_output_buffer.free()
	}
	
	return ""

}