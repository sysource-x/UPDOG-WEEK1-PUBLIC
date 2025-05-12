// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define iResolution vec3(openfl_TextureSize, 0.)
#define iChannel0 bitmap
#define texture flixel_texture2D

// third argument fix
vec4 flixel_texture2D(sampler2D bitmap, vec2 coord, float bias) {
	vec4 color = texture2D(bitmap, coord, bias);
	if (!hasTransform && !openfl_HasColorTransform)
		return color;

	if (color.a == 0.0)
		return vec4(0.0, 0.0, 0.0, 0.0);

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

// end of ShadertoyToFlixel header

//
// PUBLIC DOMAIN CRT STYLED SCAN-LINE SHADER
//
//	 by Timothy Lottes
//
// This is more along the style of a really good CGA arcade monitor.
// With RGB inputs instead of NTSC.
// The shadow mask example has the mask rotated 90 degrees for less chromatic aberration.
//
// Left it unoptimized to show the theory behind the algorithm.
//
// It is an example what I personally would want as a display option for pixel art games.
// Please take and use, change, or whatever.
//

vec2 res = vec2(320.0/1.0,240.0/1.0);

// Hardness of scanline.
//	-8.0 = soft
// -16.0 = medium
float hardScan=-10.0;

// Hardness of pixels in scanline.
// -2.0 = soft
// -4.0 = hard
float hardPix=-2.0;

// Display warp.
// 0.0 = none
// 1.0/8.0 = extreme
vec2 warp=vec2(1.0/24.0,1.0/24.0); 

// Amount of shadow mask.
float maskDark=1.0;
float maskLight=1.0;

//------------------------------------------------------------------------

// sRGB to Linear.
// Assuing using sRGB typed textures this should not be needed.
float ToLinear1(float c){
	return(c<=0.04045)?c/12.92:pow((c+0.055)/1.055,2.4);
}
vec3 ToLinear(vec3 c){
	return vec3(ToLinear1(c.r),ToLinear1(c.g),ToLinear1(c.b));
}

// Linear to sRGB.
// Assuing using sRGB typed textures this should not be needed.
float ToSrgb1(float c){
	return(c<0.0031308?c*12.92:1.055*pow(c,0.41666)-0.055);
}
vec3 ToSrgb(vec3 c){
	return vec3(ToSrgb1(c.r),ToSrgb1(c.g),ToSrgb1(c.b));
}

// Nearest emulated sample given floating point position and texel offset.
// Also zero's off screen.
vec4 getColor(sampler2D tex, vec2 pos,vec2 off){
	pos=floor(pos*res+off)/res;
	if(max(abs(pos.x-0.5),abs(pos.y-0.5))>0.5){
		return vec4(0.0);
	}
	vec4 v = flixel_texture2D(tex, pos.xy, -16.0);
	if(v.a > 0.0){
		v.rgb = v.rgb / v.a;
	}
	else{
		v = vec4(0.0);
	}
	return vec4(ToLinear(v.rgb).rgb, v.a);
}

vec4 getAlpha(sampler2D tex, vec2 pos,vec2 off){
	pos=floor(pos*res+off)/res;
	if(max(abs(pos.x-0.5),abs(pos.y-0.5))>0.5){
		return vec4(0.0);
	}
	vec4 v = flixel_texture2D(tex, pos.xy, -16.0);
	return vec4(ToLinear1(v.a));
}

// Distance in emulated pixels to nearest texel.
vec2 Dist(vec2 pos){
	pos=pos*res;return -((pos-floor(pos))-vec2(0.5));
}
		
// 1D Gaussian.
float Gaus(float pos,float scale){
	return exp2(scale*pos*pos);
}

// 3-tap Gaussian filter along horz line.
vec3 Horz3(sampler2D tex, vec2 pos, float off){
	vec4 b=getColor(tex, pos,vec2(-1.0,off));
	vec4 c=getColor(tex, pos,vec2( 0.0,off));
	vec4 d=getColor(tex, pos,vec2( 1.0,off));
	float dst=Dist(pos).x;
	// Convert distance to weight.
	float scale=hardPix;
	float wb=Gaus(dst-1.0,scale);
	float wc=Gaus(dst+0.0,scale);
	float wd=Gaus(dst+1.0,scale);
	// Return filtered sample.
	return ((b.rgb*wb)+(c.rgb*wc)+(d.rgb*wd))/((wb)+(wc)+(wd));
}

vec3 Horz3Alpha(sampler2D tex, vec2 pos, float off){
	vec4 b=getAlpha(tex, pos,vec2(-1.0,off));
	vec4 c=getAlpha(tex, pos,vec2( 0.0,off));
	vec4 d=getAlpha(tex, pos,vec2( 1.0,off));
	float dst=Dist(pos).x;
	// Convert distance to weight.
	float scale=hardPix;
	float wb=Gaus(dst-1.0,scale);
	float wc=Gaus(dst+0.0,scale);
	float wd=Gaus(dst+1.0,scale);
	// Return filtered sample.
	return ((b.rgb*wb)+(c.rgb*wc)+(d.rgb*wd))/((wb)+(wc)+(wd));
}

// 5-tap Gaussian filter along horz line.
vec3 Horz5(sampler2D tex, vec2 pos, float off){
	vec4 a=getColor(tex, pos,vec2(-2.0,off));
	vec4 b=getColor(tex, pos,vec2(-1.0,off));
	vec4 c=getColor(tex, pos,vec2( 0.0,off));
	vec4 d=getColor(tex, pos,vec2( 1.0,off));
	vec4 e=getColor(tex, pos,vec2( 2.0,off));
	float dst=Dist(pos).x;
	// Convert distance to weight.
	float scale=hardPix;
	float wa=Gaus(dst-2.0,scale);
	float wb=Gaus(dst-1.0,scale);
	float wc=Gaus(dst+0.0,scale);
	float wd=Gaus(dst+1.0,scale);
	float we=Gaus(dst+2.0,scale);
	// Return filtered sample.
	return ((a.rgb*wa)+(b.rgb*wb)+(c.rgb*wc)+(d.rgb*wd)+(e.rgb*we))/((wa)+(wb)+(wc)+(wd)+(we));
}

vec3 Horz5Alpha(sampler2D tex, vec2 pos, float off){
	vec4 a=getAlpha(tex, pos,vec2(-2.0,off));
	vec4 b=getAlpha(tex, pos,vec2(-1.0,off));
	vec4 c=getAlpha(tex, pos,vec2( 0.0,off));
	vec4 d=getAlpha(tex, pos,vec2( 1.0,off));
	vec4 e=getAlpha(tex, pos,vec2( 2.0,off));
	float dst=Dist(pos).x;
	// Convert distance to weight.
	float scale=hardPix;
	float wa=Gaus(dst-2.0,scale);
	float wb=Gaus(dst-1.0,scale);
	float wc=Gaus(dst+0.0,scale);
	float wd=Gaus(dst+1.0,scale);
	float we=Gaus(dst+2.0,scale);
	// Return filtered sample.
	return ((a.rgb*wa)+(b.rgb*wb)+(c.rgb*wc)+(d.rgb*wd)+(e.rgb*we))/((wa)+(wb)+(wc)+(wd)+(we));
}

// Return scanline weight.
float Scan(float scanValue, vec2 pos,float off){
	float dst=Dist(pos).y;
	return Gaus(dst+off, scanValue);
}

// Allow nearest three lines to effect pixel.
vec3 Tri(sampler2D tex, vec2 pos){
	vec3 a=Horz3(tex, pos,-1.0);
	vec3 b=Horz5(tex, pos, 0.0);
	vec3 c=Horz3(tex, pos, 1.0);
	float wa=Scan(hardScan, pos,-1.0);
	float wb=Scan(hardScan, pos, 0.0);
	float wc=Scan(hardScan, pos, 1.0);
	return a*wa+b*wb+c*wc;
}

vec3 TriAlpha(sampler2D tex, vec2 pos){
	vec3 a=Horz3Alpha(tex, pos,-1.0);
	vec3 b=Horz5Alpha(tex, pos, 0.0);
	vec3 c=Horz3Alpha(tex, pos, 1.0);
	float wa=Scan(hardScan/4.0, pos,-1.0);
	float wb=Scan(hardScan/4.0, pos, 0.0);
	float wc=Scan(hardScan/4.0, pos, 1.0);
	return a*wa+b*wb+c*wc;
}

// Distortion of scanlines, and end of screen alpha.
vec2 Warp(vec2 pos){
	pos=pos*2.0-1.0;		
	pos*=vec2(1.0+(pos.y*pos.y)*warp.x,1.0+(pos.x*pos.x)*warp.y);
	return pos*0.5+0.5;
}

void main(){
	vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;

	vec2 pos=Warp(fragCoord.xy/iResolution.xy+vec2(-0.333,0.0));
	pos=Warp(fragCoord.xy/iResolution.xy);

	vec4 textureColor = flixel_texture2D(bitmap, pos);
	vec4 maskColor = vec4(textureColor.a);

	textureColor.rgb = Tri(bitmap, pos);
	textureColor.rgb = ToSrgb(textureColor.rgb);

	maskColor.rgb = TriAlpha(bitmap, pos);
	//maskColor.rgb = ToSrgb(maskColor.rgb);

	vec4 finalOut = vec4(textureColor.rgb * clamp(maskColor.r, 0.0, 1.0), clamp(maskColor.r, 0.0, 1.0));

	vec4 testOut = vec4(maskColor.rgb, 1.);
			
	gl_FragColor = finalOut;
}