module tinyfiledialogs

#flag -I @VMODROOT/C
#include "tinyfiledialogs.h"
#flag @VMODROOT/C/tinyfiledialogs.c

// Decl
fn C.tinyfd_openFileDialog(&char, &char, int, &char, &char, int) &char

// Public
pub fn open_file_picker(title string, starting_path string, filters []string, filters_name string, multiple bool) string {
	ret_c_str := C.tinyfd_openFileDialog(title.str, starting_path.str, filters.len, filters.data,
		filters_name.str, int(multiple))

	if ret_c_str != &char(0) {
		return unsafe { ret_c_str.vstring() }
	}

	return ''
}
