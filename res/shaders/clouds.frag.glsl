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
uniform float u_Time;


in vec4 near_4;   
in vec4 far_4;
in vec2 v_TexCoord;
in vec3 origin;
in vec3 ray_dir;

const int NUMBER_OF_STEPS = 128;
const float MINIMUM_HIT_DISTANCE = 0.001;
const float MAXIMUM_TRACE_DISTANCE = 10000.0;

const vec3 LIGHT_POS = vec3(2.0, 3.0, 0.0);
const vec3 SPHERES[1] = vec3[](vec3(0.0, -1.0, 0.0));
const vec3 LIGHT_COLOR = vec3(20, 20, 20);
const float LIGHT_INTENSITY = 20;
const vec3 BGC = vec3(0.572, 0.772, 0.921);

#define PI 3.14159265358979323846

struct Ray
{
    vec3 ro;
    vec3 rd;
};

struct Sphere
{
    vec3 c;
    float r;
    int material;
};

struct Hit {
	float t0;
    float t1;
	int material_id;
	vec3 normal;
	vec3 origin;
    bool inside;
};



bool intersect_sphere(in Ray ray, in Sphere sphere, inout float t0, inout float t1
){
	vec3 rc = sphere.c - ray.ro;
	float radius2 = sphere.r * sphere.r;
	float tca = dot(rc, ray.rd);
	if (tca < 0.) return false;

	float d2 = dot(rc, rc) - tca * tca;
	if (d2 > radius2)
		return false;

	float thc = sqrt(radius2 - d2);
	t0 = tca - thc;
	t1 = tca + thc;

	if (t0 > t1) 
    {
        float tmp = t0;
        t0 = t1;
        t1 = tmp;
    }
    return true;
}

bool intersect_sphere_inside(in Ray ray, in Sphere sphere, inout float t0, inout float t1
){
	vec3 rc = sphere.c - ray.ro;
	float radius2 = sphere.r * sphere.r;
	float tca = dot(rc, ray.rd);
	//if (tca < 0.) return false;

	float d2 = dot(rc, rc) - tca * tca;
	//if (d2 > radius2)
		//return false;

	float thc = sqrt(radius2 - d2);
	t0 = tca - thc;
	t1 = tca + thc;

	if (t0 > t1) 
    {
        float tmp = t0;
        t0 = t1;
        t1 = tmp;
    }
    return true;
}

bool intersect_sphere_test(
	Ray ray,
	Sphere sphere,
	in out Hit hit
){
	vec3 rc = sphere.c - ray.ro;
	float radius2 = sphere.r * sphere.r;
	float tca = dot(rc, ray.rd);
    //this line breaks intersection if we start the ray inside the sphere
    //if (tca < 0.) return false;

	float d2 = dot(rc, rc) - tca * tca;
	if (d2 > radius2)
		return false;

	float thc = sqrt(radius2 - d2);
	hit.t0 = tca - thc;
	hit.t1 = tca + thc;


    if (hit.t0 < 0) {
            if (hit.t1 < 0) return false;
            else {
                hit.inside = true;
                hit.t0 = 0;
            }
        }

    return true;
}


vec3 applyFog( in vec3  rgb,       // original color of the pixel
               in float distance ) // camera to point distance
{
    const float b = 0.1;
    float fogAmount = 1.0 - exp( -distance*b );
    vec3  fogColor  = vec3(0.5,0.6,0.7);
    return mix( rgb, fogColor, fogAmount );
}

// the Henyey-Greenstein phase function
float phase(float g, float cos_theta)
{
    float denom = 1 + g * g - 2 * g * cos_theta;
    return 1 / (4 * PI) * (1 - g * g) / (denom * sqrt(denom));
}

vec3 blinn_phong(vec3 currPos, vec3 viewDir, vec3 normal);
float map(vec3 currPos);

float distance_from_sphere(in vec3 p, in vec3 c, float r)
{
    return length(p - c) - r;
}

float distanceFromPlane(in vec3 p){
    return p.y + 3;
}

//Estimate normal 
const float EPS=0.001;
vec3 estimateNormal(vec3 p){
    float xPl=map(vec3(p.x+EPS,p.y,p.z));
    float xMi=map(vec3(p.x-EPS,p.y,p.z));
    float yPl=map(vec3(p.x,p.y+EPS,p.z));
    float yMi=map(vec3(p.x,p.y-EPS,p.z));
    float zPl=map(vec3(p.x,p.y,p.z+EPS));
    float zMi=map(vec3(p.x,p.y,p.z-EPS));
    float xDiff=xPl-xMi;
    float yDiff=yPl-yMi;
    float zDiff=zPl-zMi;
    return normalize(vec3(xDiff,yDiff,zDiff));
}

vec3 integrate(in vec3 ro, in vec3 rd)
{
    float step_size = 0.1;
    float step_size_light = 0.05;
    float sigma_a = 0.9; //absorption
    float sigma_s = 0.9; //scattering
    float sigma_t = sigma_a + sigma_s; //extinction coeff
    float phase_g = 0.8; //phase function g factor

    Ray vr = Ray(ro, rd);
    Sphere sphere = Sphere(SPHERES[0], 1., 0);
    Hit view_sphere_hit;
    bool sphere_hit = intersect_sphere_test(vr, sphere, view_sphere_hit);
    if(!sphere_hit) return BGC;

    float t0 = view_sphere_hit.t0;
    float t1 = view_sphere_hit.t1;

    int ns = int(ceil((t1 - t0) / step_size));
    step_size = (t1 - t0) / ns;


    float transparency = 1; // initialize transparency to 1
    vec3 result = vec3(0.0); // initialize the volume color to 0

    //TODO temp for testing
    vec3 currPos = t0 * rd + ro;
    //return vec3(eval_density(currPos, sphere.c, sphere.r));

    for (int n = 0; n < ns; n++)
    {

        float t = t0 + step_size * (n + rand(ro));
        vec3 sample_pos= ro + t * rd; // sample position (middle of the step)
        vec3 sampleToLight = normalize(LIGHT_POS - sample_pos); //ray from sample to light
        Ray lr = Ray(sample_pos, sampleToLight);
        Hit sample_light_hit;
        bool light_hit = intersect_sphere_test(lr, sphere, sample_light_hit);
        float lh0 = sample_light_hit.t0;
        float lh1 = sample_light_hit.t1;
        
        if(sample_light_hit.inside && light_hit){

            //float density = (fbm3(sample_pos) + 1)/2.; //perlin noise shifted to [0, 1]
            float density = eval_density(sample_pos, sphere.c, sphere.r);
            // compute sample transparency using Beer's law
            float sample_transparency = exp(- density * step_size * sigma_t);
            // attenuate global transparency by sample transparency
            transparency *= sample_transparency;

            // In-scattering. 
            //Find the distance traveled by light through 
            // the volume to our sample point. Then apply Beer's law.

            //should add condition to check if ray hits the light source?
            int num_steps_light = int(ceil(lh1 / step_size_light));
            float stride_light = lh1 / num_steps_light;
            float tau = 0;
            for (int nl = 0; nl < num_steps_light; ++nl) 
            {
                    float t_light = stride_light * (nl + 0.5);
                    vec3 light_sample_pos = sample_pos + sampleToLight * t_light;
                    tau += eval_density(light_sample_pos, sphere.c, sphere.r);
                    //tau += (fbm3(light_sample_pos) + 1)/2.;
            }
            float light_attenuation = exp(-tau * stride_light * sigma_t);
            float cos_v_l = dot(-rd, sampleToLight);
            result += LIGHT_COLOR * light_attenuation * density * step_size_light * sigma_s * phase(phase_g, cos_v_l) * transparency;
        }

        //russian roulette once transparancy too low: kill some samples but 
        //increase the transparency for surviving samples
        // number 5: 1 out of 5 samples survives on average.
        if (transparency < 1e-3) {
            if (rand(sample_pos) > 1.f / 5) // we stop here
                break;
            else
                transparency *= 5; // we continue but compensate
        }

    }
    //return result;  
    //return vec3(fbm3(currPos, 3, 5.0, 1.0));
    //return vec3(eval_density(currPos, SPHERES[0], 1.));
    return BGC * transparency + result;
}

vec3 ray_march_volume(in vec3 ro, in vec3 rd)
{
    float total_distance_traveled = 0.0;

    Ray vr = Ray(ro, rd);
    Sphere sphere = Sphere(SPHERES[0], 1., 0);
 
    for (int i = 0; i < NUMBER_OF_STEPS; ++i)
    {
        float t0, t1;
        vec3 current_position = ro + total_distance_traveled * rd;

        float distance_to_closest = map(current_position);

        if (distance_to_closest < MINIMUM_HIT_DISTANCE) 
        {
            //sets t1 and t1 to intersection points
            bool hitSphere = intersect_sphere(vr, sphere, t0, t1);
            if(!hitSphere) 
            {
                vec3 normal = estimateNormal(current_position);
                vec3 bp = blinn_phong(current_position, -rd, normal);
                vec3 updated = applyFog(bp, total_distance_traveled);
                return updated;
            }
            //return vec3(t1/10., 0., 0.);
            //return integrate(ro, rd);
        }


        if (total_distance_traveled > MAXIMUM_TRACE_DISTANCE)
        {
            break;
        }
        total_distance_traveled += distance_to_closest;
    }
    return BGC;
}


float map(vec3 currPos) {
    float minv = 10000.0;
    for(int i = 0; i < SPHERES.length; i++) {
        float d = distance_from_sphere(currPos,SPHERES[i], 1.0);
        if(d < minv) {
            minv = d;
        }
    }
    //minv = min(minv, distanceFromPlane(currPos));
    return minv;
}

vec3 blinn_phong(vec3 currPos, vec3 dirToView, vec3 normal) {
    const float amb = 0.1;
    const float diff = 0.5;
    const float shininess = 3.0;
    float distanceToLight = length(LIGHT_POS - currPos);
    vec3 dirToLight = normalize(LIGHT_POS - currPos);
    float dist = distanceToLight * distanceToLight; 

    vec3 mat_color;

    vec3 checkerboard = vec3(0.0, 0.0, 0.0);
    if(mod(floor(currPos.x) + floor(currPos.z), 2) >= 1 ) checkerboard = vec3(1.0, 1.0, 1.0);

    mat_color = checkerboard;

    //ambient, diffuse, specular
    vec3 ambient = amb * LIGHT_COLOR * mat_color;
    vec3 diffuse = diff * LIGHT_COLOR * LIGHT_INTENSITY/dist * mat_color * max(dot(dirToLight, normal), 0.0);

    vec3 halfvec = normalize(dirToLight + dirToView);
    float spec = pow(max(dot(normal, halfvec), 0.0), shininess);
    vec3 specular = LIGHT_COLOR * LIGHT_INTENSITY/dist * spec;

    vec3 color = (ambient + diffuse + specular) * mat_color;

    vec3 colorGammaCorrected = pow(color, vec3(1.0 / 2.2));
    return colorGammaCorrected;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}


void main() {

    //vec2 screen_pos = (gl_FragCoord.xy) / u_Resolution.xy;
    //vec2 uv = 2*screen_pos - 1;
    //uv.x *= u_Aspect;
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
    const float fl = 2.5;
        
    // ray direction
    vec3 rd = ca * normalize( vec3(p,fl) );

    // ray differentials, not used atm
    vec2 px = (2.0*(fragCoord+vec2(1.0,0.0))-u_Resolution.xy)/u_Resolution.y;
    vec2 py = (2.0*(fragCoord+vec2(0.0,1.0))-u_Resolution.xy)/u_Resolution.y;
    vec3 rdx = ca * normalize( vec3(px,fl) );
    vec3 rdy = ca * normalize( vec3(py,fl) );
        

    vec3 shaded_color = integrate(ro, rd);
    color = vec4(shaded_color, 1.0);
}


