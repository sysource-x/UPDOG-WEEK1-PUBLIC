#pragma header

vec4 flixel_texture2D(sampler2D bitmap, vec2 coord, float bias) {
	vec4 color = texture2D(bitmap, coord, bias);
	if (!hasTransform && !openfl_HasColorTransform)
		return color;

	if (color.a == 0.0)
		return vec4(0.0);

	if (openfl_HasColorTransform || hasColorTransform) {
		color = vec4 (color.rgb / color.a, color.a);
		vec4 mult = vec4 (openfl_ColorMultiplierv.rgb, 1.0);
		color = clamp (openfl_ColorOffsetv + (color * mult), 0.0, 1.0);

		if (color.a == 0.0)
			return vec4 (0.0, 0.0, 0.0, 0.0);

		return vec4 (color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	}

	return color * openfl_Alphav;
}

uniform float dist;
uniform vec3 outlineColor;

const float pi = 3.14159265359;
const int outlineSteps = 16;

void main(){
	vec2 pixelSize = 1.0/openfl_TextureSize;
	vec4 baseTextureColor = flixel_texture2D(bitmap, openfl_TextureCoordv);

	if(dist <= 0.0){
		gl_FragColor = baseTextureColor;
		return;
	}

	if(baseTextureColor.a > 0.0){ baseTextureColor.rgb /= baseTextureColor.a; }
	else{ baseTextureColor = vec4(0.0); }

	vec4 outColor = baseTextureColor;

	float stepSize = (pi * 2.0)/float(outlineSteps);
	for(int i = 0; i < outlineSteps; i++){
		vec2 uvOffset = vec2(pixelSize.x * dist * cos(stepSize * float(i)), pixelSize.y * dist * sin(stepSize * float(i)));
		vec4 offsetTexture = flixel_texture2D(bitmap, openfl_TextureCoordv + uvOffset);
		offsetTexture.rgb = outlineColor;
		outColor.rgb = mix(offsetTexture.rgb, outColor.rgb, outColor.a);
		outColor.a = clamp(outColor.a + offsetTexture.a, 0.0, 1.0);
	}
			
	gl_FragColor = vec4(outColor.rgb * outColor.a, outColor.a);
}