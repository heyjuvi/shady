#version 300 es

#if __VERSION__ > 120
in vec2 v;
#else
attribute vec2 v;
#endif

void main( void )
{
	gl_Position = vec4(v, 1, 1);
}
