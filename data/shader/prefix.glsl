#ifdef GL_ES
precision highp float;
precision highp int;
precision highp sampler3D;
#endif

#if __VERSION__ > 120
out vec4 fragColor;
#endif

uniform vec3 iResolution;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform float iFrameRate;
uniform float iChannelTime[4];
uniform vec3 iChannelResolution[4];
uniform vec4 iMouse;
uniform vec4 iDate;
uniform float iSampleRate;
uniform vec2 SHADY_COORDINATE_OFFSET;
