#version 330 core

#include "shader_includes/utils.glsl"
//#include "shader_includes/noise.glsl"

layout(location = 0) out vec4 color;

uniform sampler2D u_Texture;
uniform vec2 u_Resolution;
uniform float u_Aspect;
uniform vec3 u_CameraPos;
uniform vec3 u_CameraFront;
uniform vec3 u_CameraRight;
uniform vec3 u_CameraUp;
uniform mat4 u_MVP;
uniform mat4 u_MVP_inverse;
uniform vec2 u_Mouse;
uniform float u_Time;


in vec2 v_TexCoord;

const int NUMBER_OF_STEPS = 128;
const float MINIMUM_HIT_DISTANCE = 0.001;
const float MAXIMUM_TRACE_DISTANCE = 10000.0;

const vec3 LIGHT_POS = vec3(2.0, 3.0, 0.0);
const vec3 SPHERES[3] = vec3[](vec3(2.0, -1.0, 0.0), vec3(0.0, -1.0, 0.0), vec3(0.0, -1.0, 2.0));
const vec3 LIGHT_COLOR = vec3(20, 20, 20);
const vec3 LIGHT_DIR = normalize(vec3(0.0, -1.0, 0.5));
const float LIGHT_INTENSITY = 20;
const vec3 BGC = vec3(0.572, 0.772, 0.921);

#define PI 3.14159265358979323846
float jitter;



// noise
// Volume raycasting by XT95
// https://www.shadertoy.com/view/lss3zr
mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );
float hash( float n )
{
    return fract(sin(n)*43758.5453);
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0 + 113.0*p.z;

    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                        mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                        mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
    return res;
}

float fbm( vec3 p )
{
    float f;
    f  = 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.12500*noise( p ); p = m*p*2.01;
    f += 0.06250*noise( p );
    return f;
}


// the Henyey-Greenstein phase function
float phase(float g, vec3 view_dir, vec3 light_dir)
{
    float cos_theta = dot(view_dir, light_dir);
    return 1 / (4 * PI) * (1 - g * g) / pow(1 + g * g - 2 * g * cos_theta, 1.5);
}

float map(vec3 currPos);

float distance_from_sphere(in vec3 p, in vec3 c, float r)
{
    return length(p - c) - r;
}

float distanceFromPlane(in vec3 p){
    return p.y + 3;
}


float intersect_volume(in vec3 ro, in vec3 rd, float maxT = 15) 
{
    float precis = 0.5; 
    float t = 0.0f;
    for(int i=0; i<NUMBER_OF_STEPS; i++ )
    {
	    float result = map( ro + rd * t);
        if( result < (precis) || t>maxT ) break;
        t += result;
    }
    return ( t>=maxT ) ? -1.0 : t;
}



vec4 integrate(in vec3 ro, in vec3 rd)
{
    float step_size = 0.2;
    float step_size_shadow = 0.1;
    int shadow_steps = 8;
    float sigma_a = 3.9; //absorption
    float sigma_s = 0.9; //scattering
    float sigma_t = sigma_a + sigma_s; //extinction coeff
    float phase_g = 0.8; //phase function g factor

    Ray vr = Ray(ro, rd);
    Sphere sphere = Sphere(SPHERES[0], 1., 0);
    Hit view_sphere_hit;

    float transparency = 1; // initialize transparency to 1



    float volumeDepth = intersect_volume(ro, rd);
    //if(volumeDepth < 0.) return BGC;


    float density = 0.0;

    vec3 pos = ro + rd * volumeDepth;
    vec3 color = vec3(0.0);
    float distanceInVolume = 0.0f;
    float signedDistance = 0.0;

    vec4 sum = vec4(0.0, 0.0, 0.0, 1.0);

    for (int n = 0; n < NUMBER_OF_STEPS; n++)
    {
        
        volumeDepth += signedDistance;

        float d = map(pos);
        if(d > 0.01)
        {
            vec3 lpos = pos - LIGHT_DIR * jitter * step_size_shadow;
            float shadow = 0.;
    
            for (int s = 0; s < shadow_steps; s++)
            {
                lpos += -LIGHT_DIR * step_size_shadow;
                float lsample = map(lpos);
                shadow += lsample;
            }
    
            density = clamp((d / float(NUMBER_OF_STEPS)) * 20.0, 0.0, 1.0);
            float s = exp((-shadow / float(shadow_steps)) * 3.);
            sum.rgb += vec3(s * density) * vec3(1.1, 0.9, .5) * sum.a;
            sum.a *= 1.-density;

            sum.rgb += exp(-map(pos + vec3(0,0.25,0.0)) * .2) * density * vec3(0.15, 0.45, 1.1) * sum.a;
        }
        pos += rd * step_size;
    }
    //return sum;
    return sum;
}


float map(vec3 currPos) {
    float minv = distance_from_sphere(currPos,SPHERES[0], 1.0);
    return 1-minv;
    for(int i = 1; i < SPHERES.length; i++) {
        float d = distance_from_sphere(currPos,SPHERES[i], 1.0);
        //minv = smooth_min(minv, d, 2.0) + fbm3(currPos);
    }
    return minv;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}


void main() 
{

    vec2 fragCoord = gl_FragCoord.xy;

    vec2 mouse = u_Mouse/u_Resolution;

    // camera	
    float cam_dist = 6.5;
    vec3 ta = vec3( 0.25, -0.75, -0.75 );
    vec3 ro = ta + vec3( cam_dist*cos(0.1*u_Time + 7.0*mouse.x), sin(mouse.y*(3.14/45)) + 3.2, cam_dist*sin(0.1*u_Time + 7.0*mouse.x) );
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );

    vec2 p = (2.0*fragCoord-u_Resolution.xy)/u_Resolution.y;

    //jitter, p.x multiplied so every pixel is sufficiently different? otherwise we see weird jitter lines
    jitter = hash(p.x * 51 + p.y + u_Time);

    // focal length
    const float fl = 1.5;
        
    // ray direction
    vec3 rd = ca * normalize( vec3(p,fl) );

    vec4 shaded_color = integrate(ro, rd);
    color = shaded_color;
    //color = vec4(shaded_color, 1.0);
}


