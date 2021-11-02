module window

import lib.gg

pub struct Window {
	pub mut:
		ctx &gg.Context = voidptr(0)
}