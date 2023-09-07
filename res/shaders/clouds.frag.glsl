#version 330 core

#include "shader_includes/utils.glsl"
#include "shader_includes/noise.glsl"

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
//uniform float u_Time;


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

//TODO move to utils
float GetFogDensity(vec3 position, float sdfDistance)
{
    const float maxSDFMultiplier = 1.0;
    bool insideSDF = sdfDistance < 0.0;
    float sdfMultiplier = insideSDF ? min(abs(sdfDistance), maxSDFMultiplier) : 0.0;
 
#if UNIFORM_FOG_DENSITY
    return sdfMultiplier;
#else
   return sdfMultiplier * abs(fbm3(position / 6.0) + 0.5);
#endif
}




vec3 integrate(in vec3 ro, in vec3 rd)
{
    float step_size = 0.2;
    float step_size_light = 0.1;
    float sigma_a = 3.9; //absorption
    float sigma_s = 0.9; //scattering
    float sigma_t = sigma_a + sigma_s; //extinction coeff
    float phase_g = 0.8; //phase function g factor

    Ray vr = Ray(ro, rd);
    Sphere sphere = Sphere(SPHERES[0], 1., 0);
    Hit view_sphere_hit;




    float volumeDepth = intersect_volume(ro, rd);
    if(volumeDepth < 0.) return BGC;


    float density = 0.0;
    float transparency = 1; // initialize transparency to 1

    vec3 pos = ro + rd * volumeDepth;

    const float MARCH_MULTIPLIER = 0.5;
    vec3 color = vec3(0.0); //final color
    const vec3 volumeAlbedo = vec3(0.8);
    const float marchSize = 0.6 * MARCH_MULTIPLIER;
    float distanceInVolume = 0.0;
    float signedDistance = 0.0;

    for (int n = 0; n < NUMBER_OF_STEPS; n++)
    {
        
        volumeDepth += max(signedDistance, 0.1);

        float signedDistance = map(pos);
        pos = ro + volumeDepth * rd;

        float d = eval_density(pos, sphere.c, sphere.r);
        if(signedDistance < 0.0)
        {
            distanceInVolume += marchSize;
            float prevTransparency = transparency;
            transparency *= BeerLambert(sigma_a * fbm3(pos), marchSize);
            float absorptionFromMarch = prevTransparency - transparency;
            for(int lightIndex = 0; lightIndex < LIGHTS.length(); lightIndex++)
    		{
                float lightVolumeDepth = 0.0f;
                vec3 lightDirection = normalize((LIGHTS[lightIndex] - pos));
                float lightDistance = length(lightDirection);
                    
                vec3 lightColor = LIGHT_COLOR * GetLightAttenuation(lightDistance); 
                if(IsColorInsignificant(lightColor)) continue;
                    
                const float lightMarchSize = 0.65f * MARCH_MULTIPLIER;

                const float ABSORPTION_CUTOFF = 0.25;
                float t = 0.0;
                float lightVisibility = 1.0;
                float signedDistance = 0.0;
                for(int i = 0; i < STEPS_SHADOW; i++)
                {                       
                    t += max(marchSize, signedDistance);
                    if(t > lightDistance || lightVisibility < ABSORPTION_CUTOFF) break;

                    vec3 position = ro + t * rd;

                    signedDistance = fbm3(position);
                    if(signedDistance < 0.0)
                    {
                        lightVisibility *= BeerLambert(sigma_a * GetFogDensity(position, signedDistance), marchSize);
                    }
                }
                color += absorptionFromMarch * lightVisibility * volumeAlbedo * lightColor;
            }
            color += absorptionFromMarch * volumeAlbedo * 0.5;
        }
    }
    //return sum;
    return color;
}


float map(vec3 currPos) {
    float minv = distance_from_sphere(currPos,SPHERES[0], 1.0);
    for(int i = 1; i < SPHERES.length; i++) {
        float d = distance_from_sphere(currPos,SPHERES[i], 1.0);
        ///minv = smooth_min(minv, d, 2.0) + fbm3(currPos);
        minv = min(minv, d);
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
    float u_Time = 0;

    // camera	
    float cam_dist = 6.5;
    vec3 ta = vec3( 0.25, -0.75, -0.75 );
    vec3 ro = ta + vec3( cam_dist*cos(0.1*u_Time + 7.0*mouse.x), sin(mouse.y*(3.14/45)) + 3.2, cam_dist*sin(0.1*u_Time + 7.0*mouse.x) );
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );

    vec2 p = (2.0*fragCoord-u_Resolution.xy)/u_Resolution.y;

    // focal length
    const float fl = 1.5;
        
    // ray direction
    vec3 rd = ca * normalize( vec3(p,fl) );

    vec3 shaded_color = integrate(ro, rd);
    color = vec4(shaded_color, 1.0);
}


