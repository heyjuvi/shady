const float pi = 3.1416;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	uv -= .5;
	uv.x *= iResolution.x / iResolution.y;
	
	float t = iGlobalTime;
	
	float b = 16. / (2. * pi);
	float d = floor(0.5 + ( atan(uv.x,uv.y) - t ) * b) / b + t;
	vec2 p = .3 * vec2(sin(d),cos(d));
	vec2 f = abs(uv - p);
	fragColor = vec4( 200. * (.05 - f.x - f.y));	
}
