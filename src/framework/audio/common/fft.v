module common

pub struct AudioEffects {
pub mut:
	fft_raw       []f32
	peak_raw      f32
	peak_smoothed f32
}
