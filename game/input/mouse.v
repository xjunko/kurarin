module input

// windows only :trollhd:
#include "@VMODROOT/game/input/mouse.h"



fn C.get_cursor_position(&int, &int)

const (
    x_pos = int(0)
    y_pos = int(0)
)

[inline]
pub fn update_cursor_ptr() {
    C.get_cursor_position(&x_pos, &y_pos)
}

pub fn get_cursor_position() []&int {
    update_cursor_ptr()
    return [&x_pos, &y_pos]
}

/*
    abit shitty but thisll works for now

    - call get_cursor_position to get int pointers
    - update_cursor_ptr to update the pointers
*/