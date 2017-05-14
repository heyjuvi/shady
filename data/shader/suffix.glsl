void main(void){
	vec4 col;
	mainImage(col,gl_FragCoord.xy);
	fragColor=col;
}
