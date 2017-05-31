void main( void )
{
	vec4 col;
	mainImage(col, gl_FragCoord.xy);

	#if __VERSION__ > 120
	fragColor = col;
	#else
	gl_FragColor = col;
	#endif
}
