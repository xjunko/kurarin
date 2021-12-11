// IT TOOK ME SO FUCKING LONG TO GET THIS RIGHT BECAUSE I MISSED ONE ARGUMENT FML KMS 
// I FUCKING HATE SHADERS SO MUCH
// SPEND 2 DAYS FOR A ONE FUCKIGN LINE FIX AAAAAAAAAAAAAAAA
@vs vs
in vec3 in_position;
in vec3 centre;
in vec2 texture_coord;

// uniform vs_params {
//     mat4 proj;
//     mat4 trans;
// };

out vec2 texture_coord_out;

void main() {
    /*
    cam = mgl32.Mat4FromRows(
        mgl32.Vec4{0.001628, 0.000000, 0.000000, -0.416667},
        mgl32.Vec4{0.000000, -0.002894, 0.000000, 0.555556},
        mgl32.Vec4{0.000000, 0.000000, 1.000000, 0.000000},
        mgl32.Vec4{0.000000, 0.000000, 0.000000, 1.000000},
    )
    */
    // TODO: unhardcode this or maybe dont idk 
    float playfield_scale = 1.453857; // HACK: not dynamic (1280x720)
    mat4 proj = mat4(
        0.001628 * playfield_scale, 0.0, 0.0, 0.0,
        0.0, -0.002894 * playfield_scale, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        -0.416667 * playfield_scale, 0.555556 * playfield_scale, 0.000000, 1.0
    );
    

    mat4 trans = mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    );

    gl_Position = proj * ((trans * vec4(in_position-centre, 1))+vec4(centre, 0));
    texture_coord_out = texture_coord;
}
@end

@fs fs
uniform sampler2D texture_in;
uniform fs_params {
    vec4 col_border;
    vec4 bullshit;
};

in vec2 texture_coord_out;
out vec4 color;

void main() {
    vec4 in_color = texture(texture_in, texture_coord_out);
    in_color *= bullshit.x;
	color = in_color * col_border;
}
@end

@program fuck vs fs