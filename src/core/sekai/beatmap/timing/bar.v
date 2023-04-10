module timing

pub struct BarLength {
pub mut:
	measure f64
	length  f64
}

pub struct BarPoint {
pub mut:
	measure           f64
	ticks_per_measure f64
	ticks             f64
}

pub struct Bars {
pub mut:
	barlengths []BarLength
	bars       []BarPoint
}

pub fn (mut bars Bars) add_bar_length(length BarLength) {
	bars.barlengths << length
}

pub fn (mut bar Bars) resolve_bars() {
	// Sort
	bar.barlengths.sort(a.measure < b.measure)

	// letsgo
	mut ticks := 0.0

	for i, current_bar in bar.barlengths {
		if i > 0 {
			prev := bar.barlengths[i - 1]
			ticks += (current_bar.measure - prev.measure) * prev.length * ticks_per_beat
		}

		bar.bars << BarPoint{
			measure: current_bar.measure
			ticks_per_measure: current_bar.length * ticks_per_beat
			ticks: ticks
		}
	}

	bar.bars = bar.bars.reverse()
}

pub fn (mut bar Bars) to_tick(measure f64, p f64, q f64) f64 {
	mut current_bar := BarPoint{
		ticks: 0xDEAD
	}

	for bar_to_find in bar.bars {
		if measure >= bar_to_find.measure {
			current_bar = bar_to_find
			break
		}
	}

	if current_bar.ticks == 0xDEAD {
		panic('Invalid bar')
	}

	// println("Measure: ${measure} | P: ${p} | Q: ${q}")

	return current_bar.ticks + (measure - current_bar.measure) * current_bar.ticks_per_measure +
		(p * current_bar.ticks_per_measure) / q
}
