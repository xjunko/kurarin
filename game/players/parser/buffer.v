module parser

import encoding.binary

struct Buffer {
pub mut:
	view []byte
}

pub fn (mut buf Buffer) read_byte() byte {
	res := buf.view[0]
	buf.view = buf.view[1..]

	return res
}

pub fn (mut buf Buffer) read_bytes(len int) []byte {
	res := buf.view[..len]
	buf.view = buf.view[len..]

	return res
}

pub fn (mut buf Buffer) read_short() int {
	res := buf.read_bytes(2)

	return int(binary.little_endian_u16(res))
}

pub fn (mut buf Buffer) read_int() int {
	res := buf.read_bytes(4)

	return int(binary.little_endian_u32(res))
}

pub fn (mut buf Buffer) read_long() int {
	res := buf.read_bytes(8)

	return int(binary.little_endian_u64(res))
}

pub fn (mut buf Buffer) read_string() string {
	if buf.read_byte() == 0x00 {
		return ''
	}

	length := buf.read_uleb128()

	return buf.read_bytes(length).bytestr()
}

pub fn (mut buf Buffer) read_uleb128() int {
	mut val, mut shift := 0, 0

	for {
		b := buf.read_byte()

		val |= ((b & 127) << shift)

		if (b & 128) == 0x00 {
			break
		}

		shift += 7
	}

	return val
}
