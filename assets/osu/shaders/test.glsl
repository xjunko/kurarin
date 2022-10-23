@vs vs_test
in vec3 position;
in vec3 color;

out vec3 color_fragment;

void main() {
    gl_Position = vec4(position.x, position.y, position.z, 1.0);
    color_fragment = color;
}
@end

@fs fs_test
in vec3 color_fragment;
out vec4 FragColor;

void main() {
    FragColor = vec4(color_fragment, 1.0);
}
@end

@program test vs_test fs_test