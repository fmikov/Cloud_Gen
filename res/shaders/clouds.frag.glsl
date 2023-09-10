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

const int NUMBER_OF_STEPS = 64;
const float MINIMUM_HIT_DISTANCE = 0.001;
const float MAXIMUM_TRACE_DISTANCE = 10000.0;

const vec3 LIGHT_POS = vec3(2.0, 3.0, 0.0);
const vec3 SPHERES[3] = vec3[](vec3(2.0, -1.0, 0.0), vec3(0.0, -1.0, 0.0), vec3(0.0, -1.0, 2.0));
const vec3 LIGHT_COLOR = vec3(1., 1., 1.);
const vec3 LIGHT_DIR = normalize(vec3(0.0, -1.0, 0.5));
const float LIGHT_INTENSITY = 20;
const vec3 BGC = vec3(0.572, 0.772, 0.921)*0.7;

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

//used to switch smoothly between sdfs to render, https://www.shadertoy.com/view/WdXGRj
//time, duration of a single SDF, transition time to the next SDF, already included in duration
float stepUp(float t, float duration, float transition_duration)
{
  float cur_time = mod(t += transition_duration, duration);
  float stp = floor(t / duration) - 1.0;
  return smoothstep(0.0, transition_duration, cur_time) + stp;
}


// the Henyey-Greenstein phase function
float phase(float g, vec3 view_dir, vec3 light_dir)
{
    float cos_theta = dot(view_dir, light_dir);
    return 1 / (4 * PI) * (1 - g * g) / pow(1 + g * g - 2 * g * cos_theta, 1.5);
}

float map(vec3 currPos);

float sdSphere(in vec3 p, in vec3 c, float r)
{
    return length(p - c) - r;
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
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


//https://shaderbits.com/blog/creating-volumetric-ray-marcher

vec3 integrate(in vec3 ro, in vec3 rd)
{
    float step_size = 0.2;
    int max_steps = NUMBER_OF_STEPS;
    float step_size_shadow = 0.1;
    int shadow_steps = 8;
    float sigma_a = 1.9; //absorption
    float sigma_s = 0.9; //scattering
    float sigma_t = sigma_a + sigma_s; //extinction coeff
    float phase_g = 0.8; //phase function g factor

    float curDensity = 0;
    float transmittance = 1.;

    //uniform density
    float density = 1.0 * step_size;

    float volumeDepth = intersect_volume(ro, rd);

    vec3 color = vec3(0.0);
    float distanceInVolume = 0.0f;
    float signedDistance = 0.0;

    vec3 pos = ro + rd * volumeDepth;

    for (int n = 0; n < max_steps; n++)
    {
        float curSample = map(pos);
        volumeDepth += signedDistance;

        if (transmittance < 0.1) {
        	break;
        }

        //sample light absorption and scattering
        if(curSample > 0.01)
        {
            //jitter start position of shadow calcs
            vec3 lpos = pos - LIGHT_DIR * jitter * step_size_shadow;
            float shadow = 0.;
    
            //march towards light
            for (int s = 0; s < shadow_steps; s++)
            {
                lpos += -LIGHT_DIR * step_size_shadow;
                float lsample = map(lpos);
                shadow += lsample;
            }
            //curDensity = clamp((curSample * density = 1/max_steps) * 20 , 0.0, 1.0);
            curDensity = clamp((curSample), 0.0, 1.0) * density;
            float light_attenuation = exp(-shadow / shadow_steps * sigma_t);
            color += light_attenuation * curDensity * transmittance * sigma_s;

            transmittance *= 1.-curDensity;
            //float sample_transparency = exp(- curSample * density * sigma_t);
            //transmittance *= sample_transparency;

            color += exp(-map(pos + vec3(0,0.25,0.0)) * .2) * curDensity * vec3(0.15, 0.45, 1.1) * transmittance;
        }
        pos += rd * step_size;
    }
    return LIGHT_COLOR * color + BGC*transmittance;
}

//we don't need high precision for deciding when we hit the volume
//if we do 1-d, we can use this function as a density function as well?
float map(vec3 currPos) {
    float distortion = fbm(currPos);
    float minv = sdSphere(currPos,SPHERES[0], 1.0) + distortion;
    return 1-minv;
    for(int i = 1; i < SPHERES.length; i++) {
        float d = sdSphere(currPos,SPHERES[i], 1.0);
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

    vec3 shaded_color = integrate(ro, rd);
    //gamma correction
    shaded_color = pow(shaded_color, vec3(1.0/2.2));
    color = vec4(shaded_color, 1.0);
}


