module cursor

pub interface ICursorController {
mut:
	cursor &Cursor
	update(f64)
}
