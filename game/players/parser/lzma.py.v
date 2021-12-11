// Very scuffed LZMA decoder using python
// idk how to wrap c library so yea
// this is only used once so i dont really care
module parser

import os

pub fn decode(path string) []byte {
	data := os.read_bytes(path) or {panic(err)}
	return decode_raw(data)
}

pub fn decode_raw(data []byte) []byte {
	// lmao
	d_shit := data.map(fn (arr byte) string { return arr.hex_full() })
	cmd := 'import lzma;data = lzma.decompress(bytearray([int(_, 16) for _ in ${d_shit.str()}]));open(\'temp\', \'wb\').write(data);print(\'> Finished!\')'
	os.write_file("bullshit", cmd) or {panic(err)}
	os.system("python bullshit")

	defer {
		os.rm("temp") or {panic(err)}
		os.rm("bullshit") or {panic(err)}
	}
	
	
	// // Done
	// defer {
	// 	os.rm('temp') or {panic(err)}
	// }

	return os.read_bytes("temp") or {panic(err)}

	
}