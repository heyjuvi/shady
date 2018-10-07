#if __VERSION__ < 150
float determinant(mat2 m){return m[0][0]*m[1][1]-m[1][0]*m[0][1];}
float determinant(mat3 m){return m[0][0]*(m[1][1]*m[2][2]-m[2][1]*m[1][2])-
                                 m[1][0]*(m[0][1]*m[2][2]-m[2][1]*m[0][2])+
                                 m[2][0]*(m[0][1]*m[1][2]-m[1][1]*m[0][2]);}
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
vec2 sinh(vec2 x){return .5*(exp(x)-exp(-x));}
vec3 sinh(vec3 x){return .5*(exp(x)-exp(-x));}
vec4 sinh(vec4 x){return .5*(exp(x)-exp(-x));}
float cosh(float x){return .5*(exp(x)+exp(-x));}
vec2 cosh(vec2 x){return .5*(exp(x)+exp(-x));}
vec3 cosh(vec3 x){return .5*(exp(x)+exp(-x));}
vec4 cosh(vec4 x){return .5*(exp(x)+exp(-x));}
float tanh(float x){return 1.-2./(exp(2.*x)+1.);}
vec2 tanh(vec2 x){return 1.-2./(exp(2.*x)+1.);}
vec3 tanh(vec3 x){return 1.-2./(exp(2.*x)+1.);}
vec4 tanh(vec4 x){return 1.-2./(exp(2.*x)+1.);}
float asinh(float x){return log(x+sqrt(x*x+1.));}
vec2 asinh(vec2 x){return log(x+sqrt(x*x+1.));}
vec3 asinh(vec3 x){return log(x+sqrt(x*x+1.));}
vec4 asinh(vec4 x){return log(x+sqrt(x*x+1.));}
float acosh(float x){return log(x+sqrt(x*x-1.));}
vec2 acosh(vec2 x){return log(x+sqrt(x*x-1.));}
vec3 acosh(vec3 x){return log(x+sqrt(x*x-1.));}
vec4 acosh(vec4 x){return log(x+sqrt(x*x-1.));}
float atanh(float x){return .5*log((1.+x)/(1.-x));}
vec2 atanh(vec2 x){return .5*log((1.+x)/(1.-x));}
vec3 atanh(vec3 x){return .5*log((1.+x)/(1.-x));}
vec4 atanh(vec4 x){return .5*log((1.+x)/(1.-x));}
/*
int abs(int x){return int(abs(float(x)));}
ivec2 abs(ivec2 x){return ivec2(abs(vec2(x)));}
ivec3 abs(ivec3 x){return ivec3(abs(vec3(x)));}
ivec4 abs(ivec4 x){return ivec4(abs(vec4(x)));}
int sign(int x){return int(sign(float(x)));}
ivec2 sign(ivec2 x){return ivec2(sign(vec2(x)));}
ivec3 sign(ivec3 x){return ivec3(sign(vec3(x)));}
ivec4 sign(ivec4 x){return ivec4(sign(vec4(x)));}
int min(int x, int y){return int(min(float(x),float(y)));}
ivec2 min(ivec2 x, ivec2 y){return ivec2(min(vec2(x),vec2(y)));}
ivec3 min(ivec3 x, ivec3 y){return ivec3(min(vec3(x),vec3(y)));}
ivec4 min(ivec4 x, ivec4 y){return ivec4(min(vec4(x),vec4(y)));}
ivec2 min(ivec2 x, int y){return ivec2(min(vec2(x),float(y)));}
ivec3 min(ivec3 x, int y){return ivec3(min(vec3(x),float(y)));}
ivec4 min(ivec4 x, int y){return ivec4(min(vec4(x),float(y)));}
int max(int x, int y){return int(max(float(x),float(y)));}
ivec2 max(ivec2 x, ivec2 y){return ivec2(max(vec2(x),vec2(y)));}
ivec3 max(ivec3 x, ivec3 y){return ivec3(max(vec3(x),vec3(y)));}
ivec4 max(ivec4 x, ivec4 y){return ivec4(max(vec4(x),vec4(y)));}
ivec2 max(ivec2 x, int y){return ivec2(max(vec2(x),float(y)));}
ivec3 max(ivec3 x, int y){return ivec3(max(vec3(x),float(y)));}
ivec4 max(ivec4 x, int y){return ivec4(max(vec4(x),float(y)));}
int clamp(int x, int min_val, int max_val){return int(clamp(float(x),float(min_val),float(max_val)));}
ivec2 clamp(ivec2 x, ivec2 min_val, ivec2 max_val){return ivec2(clamp(vec2(x),vec2(min_val),vec2(max_val)));}
ivec3 clamp(ivec3 x, ivec3 min_val, ivec3 max_val){return ivec3(clamp(vec3(x),vec3(min_val),vec3(max_val)));}
ivec4 clamp(ivec4 x, ivec4 min_val, ivec4 max_val){return ivec4(clamp(vec4(x),vec4(min_val),vec4(max_val)));}
ivec2 clamp(ivec2 x, int min_val, int max_val){return ivec2(clamp(vec2(x),float(min_val),float(max_val)));}
ivec3 clamp(ivec3 x, int min_val, int max_val){return ivec3(clamp(vec3(x),float(min_val),float(max_val)));}
ivec4 clamp(ivec4 x, int min_val, int max_val){return ivec4(clamp(vec4(x),float(min_val),float(max_val)));}
*/
float mix(float x, float y, bool a){return a?x:y;}
vec2 mix(vec2 x, vec2 y, bvec2 a){return vec2(a.x?x.x:y.x,a.y?x.y:y.y);}
vec3 mix(vec3 x, vec3 y, bvec3 a){return vec3(a.x?x.x:y.x,a.y?x.y:y.y,a.z?x.z:y.z);}
vec4 mix(vec4 x, vec4 y, bvec4 a){return vec4(a.x?x.x:y.x,a.y?x.y:y.y,a.z?x.z:y.z,a.w?x.w:y.w);}
/*
float trunc(float x){return sign(x)*floor(abs(x));}
vec2 trunc(vec2 x){return sign(x)*floor(abs(x));}
vec3 trunc(vec3 x){return sign(x)*floor(abs(x));}
vec4 trunc(vec4 x){return sign(x)*floor(abs(x));}
float round(float x){return floor(x+.5);}
vec2 round(vec2 x){return floor(x+.5);}
vec3 round(vec3 x){return floor(x+.5);}
vec4 round(vec4 x){return floor(x+.5);}
float roundEven(float x){return fract(x)==.5?2.*floor(x*.5+.5):floor(x+.5);}
vec2 roundEven(vec2 x){return fract(x)==vec2(.5)?2.*floor(x*.5+.5):floor(x+.5);}
vec3 roundEven(vec3 x){return fract(x)==vec3(.5)?2.*floor(x*.5+.5):floor(x+.5);}
vec4 roundEven(vec4 x){return fract(x)==vec4(.5)?2.*floor(x*.5+.5):floor(x+.5);}
float modf(float x, out float i){i=trunc(x);return x-i;}
vec2 modf(vec2 x, out vec2 i){i=trunc(x);return x-i;}
vec3 modf(vec3 x, out vec3 i){i=trunc(x);return x-i;}
vec4 modf(vec4 x, out vec4 i){i=trunc(x);return x-i;}
*/
#if __VERSION__ < 120
mat2 outerProduct(vec2 c, vec2 r){return mat2(c.x*r.x,c.y*r.x,c.x*r.y,c.y*r.y);}
mat3 outerProduct(vec3 c, vec3 r){return mat3(c.x*r.x,c.y*r.x,c.z*r.x,c.x*r.y,c.y*r.y,c.z*r.y,c.x*r.z,c.y*r.z,c.z*r.z);}
mat4 outerProduct(vec4 c, vec4 r){return mat4(c.x*r.x,c.y*r.x,c.z*r.x,c.w*r.x,
                                              c.x*r.y,c.y*r.y,c.z*r.y,c.w*r.y,
                                              c.x*r.z,c.y*r.z,c.z*r.z,c.w*r.z,
                                              c.x*r.w,c.y*r.w,c.z*r.w,c.w*r.w);}
mat2 transpose(mat2 m){return mat2(vec2(m[0].x,m[1].x),vec2(m[0].y,m[1].y));}
mat3 transpose(mat3 m){return mat3(vec3(m[0].x,m[1].x,m[2].x),vec3(m[0].y,m[1].y,m[2].y),vec3(m[0].z,m[1].z,m[2].z));}
mat4 transpose(mat4 m){return mat4(vec4(m[0].x,m[1].x,m[2].x,m[3].x),
                                   vec4(m[0].y,m[1].y,m[2].y,m[3].y),
                                   vec4(m[0].z,m[1].z,m[2].z,m[3].z),
                                   vec4(m[0].w,m[1].w,m[2].w,m[3].w));}
#endif
mat2 inverse(mat2 m){return mat2(m[1][1],-m[0][1],-m[1][0],m[0][0])/(m[0][0]*m[1][1]-m[1][0]*m[0][1]);}
mat3 inverse(mat3 m){return 1./determinant(m)*mat3(m[2][2]*m[1][1]-m[1][2]*m[2][1],
	                                               m[1][2]*m[2][0]-m[2][2]*m[1][0],
	                                               m[2][1]*m[1][0]-m[1][1]*m[2][0],
	                                               m[0][2]*m[2][1]-m[2][2]*m[0][1],
	                                               m[2][2]*m[0][0]-m[0][2]*m[2][0],
	                                               m[0][1]*m[2][0]-m[2][1]*m[0][0],
	                                               m[1][2]*m[0][1]-m[0][2]*m[1][1],
	                                               m[0][2]*m[1][0]-m[1][2]*m[0][0],
	                                               m[1][1]*m[0][0]-m[0][1]*m[1][0]);}
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
vec4 textureProj(lowp sampler2D sampler, vec3 uv){return texture2DProj(sampler,uv);}
vec4 textureProj(lowp sampler2D sampler, vec3 uv, float bias){return texture2DProj(sampler,uv,bias);}
vec4 textureProj(lowp sampler2D sampler, vec4 uv){return texture2DProj(sampler,uv);}
vec4 textureProj(lowp sampler2D sampler, vec4 uv, float bias){return texture2DProj(sampler,uv,bias);}
vec4 texture(lowp samplerCube sampler, vec3 uv){return textureCube(sampler,uv);}
vec4 texture(lowp samplerCube sampler, vec3 uv, float bias){return textureCube(sampler,uv,bias);}
#if __VERSION__ > 100
vec4 texture(lowp sampler1D sampler, float uv){return texture1D(sampler,uv);}
vec4 texture(lowp sampler1D sampler, float uv, float bias){return texture1D(sampler,uv,bias);}
vec4 textureProj(lowp sampler1D sampler, vec2 uv){return texture1DProj(sampler,uv);}
vec4 textureProj(lowp sampler1D sampler, vec2 uv, float bias){return texture1DProj(sampler,uv,bias);}
vec4 textureProj(lowp sampler1D sampler, vec4 uv){return texture1DProj(sampler,uv);}
vec4 textureProj(lowp sampler1D sampler, vec4 uv, float bias){return texture1DProj(sampler,uv,bias);}
vec4 texture(lowp sampler3D sampler, vec3 uv){return texture3D(sampler,uv);}
vec4 texture(lowp sampler3D sampler, vec3 uv, float bias){return texture3D(sampler,uv,bias);}
vec4 textureProj(lowp sampler3D sampler, vec4 uv){return texture3DProj(sampler,uv);}
vec4 textureProj(lowp sampler3D sampler, vec4 uv, float bias){return texture3DProj(sampler,uv,bias);}
#endif
#endif
