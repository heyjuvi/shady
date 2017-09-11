vec2 rot2D(vec2 p, float angle)
{
	angle = radians(angle);
	float s = sin(angle);
	float c = cos(angle);

	return p * mat2(c,s,-s,c);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = (fragCoord.xy - iResolution.xy * .5) / iResolution.y;
	vec2  m = (iMouse.xy / iResolution.xy) * 2. - 1.;

	vec3 dir = vec3(uv, 1.);
	dir.yz = rot2D(dir.yz,  90. * m.y);
	dir.xz = rot2D(dir.xz, 10. * iTime);

	fragColor = texture(iChannel0, dir);
}
