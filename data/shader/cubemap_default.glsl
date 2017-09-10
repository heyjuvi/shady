void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy/iResolution.xy;
    uv-=.5;
    uv.x*=iResolution.x/iResolution.y;
    
    vec3 dir = vec3(uv, 1.);
    
    float t0=iTime*.5;
    dir.xz *= mat2(sin(t0),cos(t0),-cos(t0),sin(t0));
    
	fragColor = texture(iChannel0, dir);
}
