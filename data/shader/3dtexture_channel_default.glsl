// Simple volume rendering test of a cube with random-opacity cells.
// We're not being too careful with sampling positions or optimization;
// just marching through the volume, calculating the lighting (which
// all comes directly from above) at each step, and displaying the result.

// At the moment, we do get banding artifacts near the darker edge when
// the lighting direction is slightly off from directly above;
// This might be due to sampling positions along the light ray leaving the
// cube and improperly handling transparency, but I'm not sure.

// Returns the per-cell opacity of the volume at the given texture coordinate.
float sampleA(vec3 texcoord){
    return texture(iChannel0, texcoord).r/4.0;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Set up a coordinate system - x pointing right, y pointing up.
	vec2 uv = 2.0*(fragCoord.xy-iResolution.xy*0.5) / iResolution.x;
    
    // Camera controls.
    // We use a left-handed DirectX-style coordinate system: x points
    // to the right, y points up, and z points into the screen.
    vec3 co = vec3(sin(iTime*0.5), 0.0, -3.0);
    vec3 ci = vec3(uv.x, uv.y, 1.0);
    
    // Our raytracing code for the cube is very simplified,
    // since we'll always assume the camera's x and y coordinates
    // remain between -1 and 1 - i.e. we're always looking into
    // the front face of the cube.
    
    // t is just a variable to store our position (!= distance)
    // along the ray. Since it doesn't directly store distance,
    // we are fudging things a bit.
    
    // first hit
    // (co+ci*t).z=-1.0
    // -> t = (-1.0-co.z)/ci.z
    float t = (-1.0-co.z)/ci.z;
    
    // Step size: size of cube/# of pixels
    float dt = 2.0/32.0;
   
    // Accumulated color
    vec4 col = vec4(0.0); //a*rgb, a - in-front blending.
    
    // Current position
    vec3 p = co+ci*t;
    
    // Derivation:
    //float tToEdge = min((1.0-sign(ci.x)*co.x)/abs(ci.x),
    //                    (1.0-sign(ci.y)*co.y)/abs(ci.y));
    
    //  (1-cox)/ci.x>0 <=> ci.x>0 and cox<1 (maybe)
    //                  or ci.x<0 and cox>1 (no)
    // Assume we start within the cube, so abs(cox)<1.
    // (-1-cox)/ci.x>0 <=> ci.x>0 and cox<-1 (no)
    //                  or ci.x<0 and cox>-1 (maybe)
    
    for(int i=0; i<32; i++){
        p += ci*dt; //p = co+ci*(t+i*dt);
        
        // are we inside the cube?
        if(max(abs(p.x),max(abs(p.y),abs(p.z)))<1.0){
            // Sample opacity at current position
            vec3 uvw = p*0.5+vec3(0.5);
            float a = sampleA(uvw);
            
            // Lighting: how much light is transmitted from above?
            float upT = 1.0; // upwards transparency
            
            // actually, let's have some light directing!
            float dx = 2.0*(iMouse.x-iResolution.x*0.5)/iResolution.x;
            
            // New y sampling coordinate.
            // Since we want to sample each of the cells above the current one
            // without blending, we'll need to round its y coordinate to a
            // half-cell position:
            // positions:
            vec3 uvw2 = uvw;
            uvw2.y = (floor(uvw2.y*32.0)+0.5)/32.0;
            uvw2.x += dx*(uvw2.y-uvw.y); // Step along the light ray that amount
            
            // Handle the transparency loss due to the current cube:
            // light through dt units = 1.0-a
            // light through 2*dt units = (1.0-a)^2
            upT *= pow(1.0-a, (uvw2.y-uvw.y)*32.0+0.5);
            
            for(int j = 1; j<32; j++){
                // Move uvw2 one cell upwards:
                uvw2.y += 1.0/32.0;
                uvw2.x += dx/32.0;
                
                if(uvw2.y<1.0 &&
                   0.0<uvw2.x && uvw2.x<1.0){
                    upT *= (1.0-sampleA(uvw2));
                }
            }
            
            // For blending on the edges: how far is it to the edge
            // of the cube? (note: not handling ci.x=0 or ci.y=0 case)
            
            float tToEdge = min(1.0/abs(ci.x)-p.x/ci.x,
                                1.0/abs(ci.y)-p.y/ci.y);
            
            // Derivation: We only look at sides of the cube.
            // Suppose ci.x>0. Then t to edge is  (1-p.x)/ci.x.
            //      If ci.x<0, then t to edge is (-1-p.x)/ci.x
            // So along x, t to edge is sign(ci.x)/ci.x - p.x/ci.x
            //                        =     1/abs(ci.x) - p.x/ci.x.
            // Equation along y is analogous (just substitute y for x)
            
            if(tToEdge<dt){
                // Beer-Lambert-style blending.
                if(tToEdge<0.000001){
                    a = 0.0;
                }else{
                    // opacity per dt units = a
                    // opacity per 2*dt units = 1-(1-a)^2
                    a = 1.0-pow(1.0-a,tToEdge/dt);
                }
            }
            
            // Premultiplied alpha blending
            // per https://www.teamten.com/lawrence/graphics/premultiplication/
            // rgb color 1, lighting upT, opacity a
            vec4 below = vec4(upT*a, upT*a, upT*a, a);
            col = col + (1.0-col.a)*below;
        }
    }
    
    // alpha-composite with black behind - this turns out to be trivial :|
    vec4 sky = vec4(0.0);
    
    col = col + (1.0-col.a)*sky;
    
    // and convert to gamma for display!
	fragColor = vec4(pow(col.rgb, vec3(1.0/2.2)), 1.0);
}
