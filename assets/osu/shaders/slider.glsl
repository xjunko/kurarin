@vs vs
in vec3 in_position;
in vec3 centre;
in vec2 texture_coord;

uniform vs_uniform {
    mat4 proj;
    vec4 slider_beat_scale; // it was a float but idk sokol is being retarded so had to do this to workaround that
};

out vec2 v_uv;

void main() {
    mat4 trans = mat4(
        slider_beat_scale.x, 0.0, 0.0, 0.0,
        0.0, slider_beat_scale.x, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    );

    gl_Position = proj * (
            (
                (trans * vec4(in_position, 1)) - (trans * vec4(centre, 1)) + (trans * vec4(0, 0, 0, 1))
        ) + vec4(centre, 0)
    );
    v_uv = texture_coord;
}
@end

@fs fs
in vec2 v_uv;
out vec4 color;
uniform fs_uniform {
    vec3 colBody;
    vec3 colBorder;
    vec3 borderMultiplier;
};

const float defaultTransitionSize = 0.011;
const float defaultBorderSize = 0.11;
const float outerShadowSize = 0.08;

vec4 getInnerBodyColor(in vec4 bodyColor)
{
	float brightnessMultiplier = 0.25;
	bodyColor.r = min(1.0, bodyColor.r * (1.0 + 0.5 * brightnessMultiplier) + brightnessMultiplier);
	bodyColor.g = min(1.0, bodyColor.g * (1.0 + 0.5 * brightnessMultiplier) + brightnessMultiplier);
	bodyColor.b = min(1.0, bodyColor.b * (1.0 + 0.5 * brightnessMultiplier) + brightnessMultiplier);
	return vec4(bodyColor);
}

vec4 getOuterBodyColor(in vec4 bodyColor)
{
	float darknessMultiplier = 0.1;
	bodyColor.r = min(1.0, bodyColor.r / (1.0 + darknessMultiplier));
	bodyColor.g = min(1.0, bodyColor.g / (1.0 + darknessMultiplier));
	bodyColor.b = min(1.0, bodyColor.b / (1.0 + darknessMultiplier));
	return vec4(bodyColor);
}

void main() {
    // here goes nothing
    float borderSize = defaultBorderSize * borderMultiplier.r;
    const float transitionSize = defaultTransitionSize;

    // output
    vec4 outColor = vec4(0.0);

    //
    // vec3 colBorder = vec3(1.0, 1.0, 1.0);
    // vec3 colBody = vec3(0.0, 0.0, 0.0);
    float bodyAlphaMultiplier = 1.0;
    float bodyColorSaturation = 1.0;

    // Colors
    vec4 borderColor = vec4(colBorder.x, colBorder.y, colBorder.z, 1.0);
    vec4 bodyColor = vec4(colBody.x, colBody.y, colBody.z, 0.7*bodyAlphaMultiplier);
    vec4 outerShadowColor = vec4(0, 0, 0, 0.25);
    vec4 innerBodyColor = getInnerBodyColor(bodyColor);
    vec4 outerBodyColor = getOuterBodyColor(bodyColor);

    innerBodyColor.rgb *= bodyColorSaturation;
    outerBodyColor.rgb *= bodyColorSaturation;

    // osu!next (lazer) style
    if (borderMultiplier.g == 1.0f) {
        outerBodyColor.rgb = bodyColor.rgb * bodyColorSaturation;
        outerBodyColor.a = 1.0*bodyAlphaMultiplier;
        innerBodyColor.rgb = bodyColor.rgb * 0.5 * bodyColorSaturation;
        innerBodyColor.a = 0.0;
    }

    // HACK: this fixes rough edges
    if (borderMultiplier.r < 0.01)
		borderColor = outerShadowColor;

    // Conditional Variant
    if (v_uv.x < outerShadowSize - transitionSize) // just shadow
	{
		float delta = v_uv.x / (outerShadowSize - transitionSize);
		outColor = mix(vec4(0), outerShadowColor, delta);
	}
	if (v_uv.x > outerShadowSize - transitionSize && v_uv.x < outerShadowSize + transitionSize) // shadow + border
	{
		float delta = (v_uv.x - outerShadowSize + transitionSize) / (2.0*transitionSize);
		outColor = mix(outerShadowColor, borderColor, delta);
	}
	if (v_uv.x > outerShadowSize + transitionSize && v_uv.x < outerShadowSize + borderSize - transitionSize) // just border
	{
		outColor = borderColor;
	}
	if (v_uv.x > outerShadowSize + borderSize - transitionSize && v_uv.x < outerShadowSize + borderSize + transitionSize) // border + outer body
	{
		float delta = (v_uv.x - outerShadowSize - borderSize + transitionSize) / (2.0*transitionSize);
		outColor = mix(borderColor, outerBodyColor, delta);
	}
	if (v_uv.x > outerShadowSize + borderSize + transitionSize) // outer body + inner body
	{	
		float size = outerShadowSize + borderSize + transitionSize;
		float delta = ((v_uv.x - size) / (1.0-size));
		outColor = mix(outerBodyColor, innerBodyColor, delta);
	}

    color = outColor;
}
@end

@program osu_slider vs fs
