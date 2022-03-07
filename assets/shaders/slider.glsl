// IT TOOK ME SO FUCKING LONG TO GET THIS RIGHT BECAUSE I MISSED ONE ARGUMENT FML KMS 
// I FUCKING HATE SHADERS SO MUCH
// SPEND 2 DAYS FOR A ONE FUCKIGN LINE FIX AAAAAAAAAAAAAAAA
@vs vs
in vec3 in_position;
in vec3 centre;
in vec2 texture_coord;

out vec2 v_uv;

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
    v_uv = texture_coord;
}
@end

@fs fs
in vec2 v_uv;
out vec4 color;

// Lazer use 1.0 iirc
const float defaultTransitionSize = 0.01;
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
    float borderSize = defaultBorderSize;
    const float transitionSize = defaultTransitionSize;

    // output
    vec4 outColor = vec4(0.0);

    //
    vec3 colBorder = vec3(1.0, 1.0, 1.0);
    vec3 colBody = vec3(0.0, 0.0, 0.0);
    float bodyAlphaMultiplier = 1.0;
    float bodyColorSaturation = 1.0;

    // dunamic bullsh titerary
    vec4 borderColor = vec4(colBorder.x, colBorder.y, colBorder.z, 1.0);
    vec4 bodyColor = vec4(colBody.x, colBody.y, colBody.z, 0.7*bodyAlphaMultiplier);
    vec4 outerShadowColor = vec4(0, 0, 0, 0.25);
    vec4 innerBodyColor = getInnerBodyColor(bodyColor);
    vec4 outerBodyColor = getOuterBodyColor(bodyColor);

    innerBodyColor.rgb *= bodyColorSaturation;
    outerBodyColor.rgb *= bodyColorSaturation;

    // cond varianctt
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

@program fuck vs fs