#include "windows.h"
#include "winuser.h"

void get_cursor_position(int *x_ptr, int *y_ptr)
{
    POINT cursor;
    GetCursorPos(&cursor);

    // deez
    *x_ptr = (int)(cursor.x);
    *y_ptr = (int)(cursor.y);
}
