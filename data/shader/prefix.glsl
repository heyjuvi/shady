#version 330

#ifdef GL_ES
precision highp float;
precision highp int;
#endif

#if __VERSION__ > 120
out vec4 fragColor;
#endif

uniform vec3 iResolution;
uniform float iGlobalTime;
uniform vec4 iMouse;
