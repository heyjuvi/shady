#if __VERSION__ < 150
float determinant(mat2 m){return m[0][0]*m[1][1]-m[1][0]*m[0][1];}
float determinant(mat4 m){
  float b00=m[0][0]*m[1][1]-m[0][1]*m[1][0],
        b01=m[0][0]*m[1][2]-m[0][2]*m[1][0],
        b02=m[0][0]*m[1][3]-m[0][3]*m[1][0],
        b03=m[0][1]*m[1][2]-m[0][2]*m[1][1],
        b04=m[0][1]*m[1][3]-m[0][3]*m[1][1],
        b05=m[0][2]*m[1][3]-m[0][3]*m[1][2],
        b06=m[2][0]*m[3][1]-m[2][1]*m[3][0],
        b07=m[2][0]*m[3][2]-m[2][2]*m[3][0],
        b08=m[2][0]*m[3][3]-m[2][3]*m[3][0],
        b09=m[2][1]*m[3][2]-m[2][2]*m[3][1],
        b10=m[2][1]*m[3][3]-m[2][3]*m[3][1],
        b11=m[2][2]*m[3][3]-m[2][3]*m[3][2];
  return b00*b11-b01*b10+b02*b09+b03*b08-b04*b07+b05*b06;}
#endif
#if __VERSION__ <= 120
float sinh(float x){return .5*(exp(x)-exp(-x));}
float cosh(float x){return .5*(exp(x)+exp(-x));}
float tanh(float x){return 1.-2./(exp(2.*x)+1.);}
float asinh(float x){return log(x+sqrt(x*x+1.));}
float acosh(float x){return log(x+sqrt(x*x-1.));}
float atanh(float x){return .5*log((1.+x)/(1.-x));}
/*
float round(float x){return floor(x+.5);}
vec2 round(vec2 x){return floor(x+.5);}
vec3 round(vec3 x){return floor(x+.5);}
vec4 round(vec4 x){return floor(x+.5);}
*/
mat3 transpose(mat3 m){return mat3(vec3(m[0].x,m[1].x,m[2].x),vec3(m[0].y,m[1].y,m[2].y),vec3(m[0].z,m[1].z,m[2].z));}
mat2 inverse(mat2 m){return mat2(m[1][1],-m[0][1],-m[1][0],m[0][0])/(m[0][0]*m[1][1]-m[1][0]*m[0][1]);}
mat4 inverse(mat4 m){
  float a00=m[0][0],a01=m[0][1],a02=m[0][2],a03=m[0][3],
        a10=m[1][0],a11=m[1][1],a12=m[1][2],a13=m[1][3],
        a20=m[2][0],a21=m[2][1],a22=m[2][2],a23=m[2][3],
        a30=m[3][0],a31=m[3][1],a32=m[3][2],a33=m[3][3],
        b00=a00*a11-a01*a10, b01=a00*a12-a02*a10,
        b02=a00*a13-a03*a10, b03=a01*a12-a02*a11,
        b04=a01*a13-a03*a11, b05=a02*a13-a03*a12,
        b06=a20*a31-a21*a30, b07=a20*a32-a22*a30,
        b08=a20*a33-a23*a30, b09=a21*a32-a22*a31,
        b10=a21*a33-a23*a31, b11=a22*a33-a23*a32,

        det=b00*b11-b01*b10+b02*b09+b03*b08-b04*b07+b05*b06;

  return mat4(a11*b11-a12*b10+a13*b09,
              a02*b10-a01*b11-a03*b09,
              a31*b05-a32*b04+a33*b03,
              a22*b04-a21*b05-a23*b03,
              a12*b08-a10*b11-a13*b07,
              a00*b11-a02*b08+a03*b07,
              a32*b02-a30*b05-a33*b01,
              a20*b05-a22*b02+a23*b01,
              a10*b10-a11*b08+a13*b06,
              a01*b08-a00*b10-a03*b06,
              a30*b04-a31*b02+a33*b00,
              a21*b02-a20*b04-a23*b00,
              a11*b07-a10*b09-a12*b06,
              a00*b09-a01*b07+a02*b06,
              a31*b01-a30*b03-a32*b00,
              a20*b03-a21*b01+a22*b00)/det;
}
vec4 texture(lowp sampler2D sampler, vec2 uv){return texture2D(sampler,uv);}
vec4 texture(lowp sampler2D sampler, vec2 uv, float bias){return texture2D(sampler,uv,bias);}
vec4 texture(lowp samplerCube sampler, vec3 uv){return textureCube(sampler,uv);}
vec4 texture(lowp samplerCube sampler, vec3 uv, float bias){return textureCube(sampler,uv,bias);}
#endif
