import gg.m4

fn main() {
	scl := f32(800.0 / 384 * 3/4)
	mut cam := m4.ortho(-1280.0/2.0, 1280.0/2.0, 720.0/2.0, -720.0/2.0, 1, -1)

	mut mat := m4.zero_m4()
	mat.set_f(0,0, scl)
	mat.set_f(1,1, scl)
	mat.set_f(2,2, 1)
	mat.set_f(3,3, 1)

	mut default_scale := m4.zero_m4()
	default_scale.set_f(0,0, 1)
	default_scale.set_f(1,1, 1)
	default_scale.set_f(2,2, 1)
	default_scale.set_f(3,3, 1)

	mut v1 := m4.zero_v4()
	mut v2 := m4.zero_v4()
	mut v3 := m4.zero_v4()

	v2.e[2] = -1
	v3.e[1] = 1

	mut look_at := m4.look_at(v1, v2, v3)
	mut playfield_mat := m4.zero_m4()
	playfield_mat.copy(default_scale)

	// size
	playfield_mat.set_f(3,0, -512*scl/2)
	playfield_mat.set_f(3,1, -384*scl/2)

	game_camera := cam * look_at * playfield_mat * mat

	test := m4.vec3(320, 240, 0)

	println(m4.mul_vec(game_camera, test))
}

