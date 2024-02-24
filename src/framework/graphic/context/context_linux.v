module context

fn C._sapp_glx_swapinterval(int)

pub fn vsync(enable bool) {
	if !enable {
		C._sapp_glx_swapinterval(0)
	}
}
