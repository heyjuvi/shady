void main( void )
{
	vec4 col;
	mainImage(col, gl_FragCoord.xy + SHADY_COORDINATE_OFFSET);

	#if __VERSION__ > 120
	fragColor = col;
	#else
	gl_FragColor = col;
	#endif
}
