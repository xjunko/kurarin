module common

pub struct AudioEffects {
pub mut:
	fft_raw       []f32 = []f32{len: 512}
	peak_raw      f32
	peak_smoothed f32
}
