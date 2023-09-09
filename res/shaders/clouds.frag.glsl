#version 330 core

#include "shader_includes/utils.glsl"
//include "shader_includes/noise.glsl"

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
const int STEPS_SHADOW = 8;
const float MINIMUM_HIT_DISTANCE = 0.001;
const float MAXIMUM_TRACE_DISTANCE = 10000.0;

const vec3 LIGHT_POS = vec3(2.0, 3.0, 0.0);
const vec3 SPHERES[3] = vec3[](vec3(2.0, -1.0, 0.0), vec3(0.0, -1.0, 0.0), vec3(0.0, -1.0, 2.0));
const vec3 LIGHT_COLOR = vec3(20, 20, 20);
const vec3 LIGHT_DIR = normalize(vec3(0.0, -1.0, 0.5));
const vec3 LIGHTS[1] = vec3[](LIGHT_POS);
const float LIGHT_INTENSITY = 20;
const vec3 BGC = vec3(0.572, 0.772, 0.921);

#define PI 3.14159265358979323846



// the Henyey-Greenstein phase function
float phase(float g, vec3 view_dir, vec3 light_dir)
{
    float cos_theta = dot(view_dir, light_dir);
    return 1 / (4 * PI) * (1 - g * g) / pow(1 + g * g - 2 * g * cos_theta, 1.5);
}

float stepUp(float t, float len, float smo)
{
  float tt = mod(t += smo, len);
  float stp = floor(t / len) - 1.0;
  return smoothstep(0.0, smo, tt) + stp;
}
float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
float hash( float n )
{
    return fract(sin(n)*43758.5453);
}
mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );
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

float map( in vec3 p )
{
	vec3 q = p - vec3(0.0,0.5,1.0)*u_Time;
    float f = fbm(q);
    float s1 = 1.0 - length(p * vec3(0.5, 1.0, 0.5)) + f * 2.2;
    float s2 = 1.0 - length(p * vec3(0.1, 1.0, 0.2)) + f * 2.5;
    float torus = 1. - sdTorus(p * 2.0, vec2(6.0, 0.005)) + f * 3.5;
    float s3 = 1.0 - smooth_min(smooth_min(
                           length(p * 1.0 - vec3(cos(u_Time * 3.0) * 6.0, sin(u_Time * 2.0) * 5.0, 0.0)),
                           length(p * 2.0 - vec3(0.0, sin(u_Time) * 4.0, cos(u_Time * 2.0) * 3.0)), 4.0),
                           length(p * 3.0 - vec3(cos(u_Time * 2.0) * 3.0, 0.0, sin(u_Time * 3.3) * 7.0)), 4.0) + f * 2.5;
    
    float t = mod(stepUp(u_Time, 4.0, 1.0), 4.0);
    
    //this is used to decide which shape will be shown, transitions smoothly thanks to 't'
	float d = mix(s1, s2, clamp(t, 0.0, 1.0));
    d = mix(d, torus, clamp(t - 1.0, 0.0, 1.0));
    d = mix(d, s3, clamp(t - 2.0, 0.0, 1.0));
    d = mix(d, s1, clamp(t - 3.0, 0.0, 1.0));
    
	return min(max(0.0, d), 1.0);
}

float map2(in vec3 p)
{
    vec3 q = p - vec3(0.0,0.5,1.0)*u_Time;
    float f = fbm(q);
    float s1 = 1.0 - length(p * vec3(0.5, 1.0, 0.5)) + f * 2.2 ;
    return s1;
}

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


#define MAX_STEPS 48
#define SHADOW_STEPS 8
#define VOLUME_LENGTH 15.
#define SHADOW_LENGTH 2.
float jitter;

vec4 integrate(in vec3 ro, in vec3 rd)
{
    float density = 0.;

    float stepLength = VOLUME_LENGTH / float(MAX_STEPS);
    float shadowStepLength = SHADOW_LENGTH / float(SHADOW_STEPS);
    vec3 light = normalize(vec3(1.0, 2.0, 1.0));

    vec4 sum = vec4(0., 0., 0., 1.);
    
    vec3 pos = ro + rd* jitter * stepLength;
    
    for (int i = 0; i < MAX_STEPS; i++)
    {
        if (sum.a < 0.1) {
        	break;
        }
        float d = map(pos);
    
        if( d > 0.001)
        {
            vec3 lpos = pos + light * jitter * shadowStepLength;
            float shadow = 0.;
    
            for (int s = 0; s < SHADOW_STEPS; s++)
            {
                lpos += light * shadowStepLength;
                float lsample = map(lpos);
                shadow += lsample;
            }
    
            density = clamp((d / float(MAX_STEPS)) * 20.0, 0.0, 1.0);
            float s = exp((-shadow / float(SHADOW_STEPS)) * 3.);
            sum.rgb += vec3(s * density) * vec3(1.1, 0.9, .5) * sum.a;
            sum.a *= 1.-density;

            sum.rgb += exp(-map(pos + vec3(0,0.25,0.0)) * .2) * density * vec3(0.15, 0.45, 1.1) * sum.a;
        }
        pos += rd * stepLength;
    }

    return sum;
}


mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}


void main() 
{
    

    vec2 fragCoord = gl_FragCoord.xy;

    vec2 mouse = u_Mouse/u_Resolution;
    float u_Time = 0;

    // camera	
    float cam_dist = 6.5;
    vec3 ta = vec3( 0.25, -0.75, -0.75 );
    vec3 ro = ta + vec3( cam_dist*cos(0.1*u_Time + 7.0*mouse.x), sin(mouse.y*(3.14/45)) + 3.2, cam_dist*sin(0.1*u_Time + 7.0*mouse.x) );
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );

    vec2 p = (2.0*fragCoord-u_Resolution.xy)/u_Resolution.y;
    jitter = hash(p.x + p.y * 57.0 + u_Time);
    // focal length
    const float fl = 1.5;
        
    // ray direction
    vec3 rd = ca * normalize( vec3(p,fl) );


    vec4 col = integrate(ro, rd);
    vec3 result = col.rgb + mix(vec3(0.3, 0.6, 1.0), vec3(0.05, 0.35, 1.0), p.y + 0.75) * (col.a);
    
    float sundot = clamp(dot(rd,normalize(vec3(1.0, 2.0, 1.0))),0.0,1.0);
    result += 0.4*vec3(1.0,0.7,0.3)*pow( sundot, 2.0 );
    result = pow(result, vec3(1.0/2.2));
    color = vec4(result, 1.0);

    //vec3 shaded_color = integrate(ro, rd);
    //color = vec4(shaded_color, 1.0);
    //color = integrate(ro, rd);
}


