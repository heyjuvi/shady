// Based on
// Hash without Sine
// Creative Commons Attribution-ShareAlike 4.0 International Public License
// Created by David Hoskins.

// https://www.shadertoy.com/view/4djSRW

#define ITERATIONS 4

// *** Change these to suit your range of random numbers..

// *** Use this for integer stepped ranges, ie Value-Noise/Perlin noise functions.
#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)
#define HASHSCALE4 vec4(.1031, .1030, .0973, .1099)

float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
	p3 += dot(p3, p3.yzx + 19.19);
	return fract((p3.x + p3.y) * p3.z);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 position = fragCoord.xy;
	vec2 uv = fragCoord.xy / iResolution.xy;
	float a = 0.0, b = a;
	for (int t = 0; t < ITERATIONS; t++)
	{
			float v = float(t+1)*.152;
			vec2 pos = (position * v + mod(iTime,100.) * 1500. + 50.0);
			a += hash12(pos);
	}
	vec3 col = vec3(a/float(ITERATIONS));
	fragColor = vec4(col, 1.0);
}
