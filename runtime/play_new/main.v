module play_new

// import osu
// import osu.database
// import scenes

import old_gui


// Massive WIP: just fallback to old gui for now
pub fn main() {
	old_gui.main()
	// mut g_db := &database.OsuDatabase{}

	// mut g_osu := &osu.Osu{
	// 	g_db: g_db
	// }
	// // g_osu.init(ctx)

	// mut loading := scenes.LoadingScene{g_osu: g_osu}
	// // loading.init(ctx)
	// loading.update(0)
	
	// for loading.status != .done {
	// 	println("LOAINDG")
	// }

	// println("DOEN!")
}