#version 330 core

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

const int NUMBER_OF_STEPS = 32;
const float MINIMUM_HIT_DISTANCE = 0.001;
const float MAXIMUM_TRACE_DISTANCE = 1000.0;

const vec3 LIGHT_POS = vec3(3.0, 3.0, 4.0);
const vec3 SPHERES[3] = vec3[](vec3(0.0, -1.0, 0.0), vec3(1.0, 1.0, 1.0), vec3(1.0, -1.0, 1.0));
const vec3 LIGHT_COLOR = vec3(1.0, 0.0, 0.0);
const vec3 SPHERE_POS = vec3(0.5, 0.5, 0.0);

struct ray {
    vec3 pos;
    vec3 dir;
};

vec3 blinn_phong(vec3 currPos, vec3 viewDir, vec3 normal);
float distanceToClosest(vec3 currPos);

float distance_from_sphere(in vec3 p, in vec3 c, float r)
{
    return length(p - c) - r;
}

float distanceFromPlane(in vec3 p){
    return p.y + 1;
}

//Estimate normal 
const float EPS=0.001;
vec3 estimateNormal(vec3 p){
    float xPl=distanceToClosest(vec3(p.x+EPS,p.y,p.z));
    float xMi=distanceToClosest(vec3(p.x-EPS,p.y,p.z));
    float yPl=distanceToClosest(vec3(p.x,p.y+EPS,p.z));
    float yMi=distanceToClosest(vec3(p.x,p.y-EPS,p.z));
    float zPl=distanceToClosest(vec3(p.x,p.y,p.z+EPS));
    float zMi=distanceToClosest(vec3(p.x,p.y,p.z-EPS));
    float xDiff=xPl-xMi;
    float yDiff=yPl-yMi;
    float zDiff=zPl-zMi;
    return normalize(vec3(xDiff,yDiff,zDiff));
}

vec3 ray_march(in vec3 ro, in vec3 rd)
{
    float total_distance_traveled = 0.0;


 
    for (int i = 0; i < NUMBER_OF_STEPS; ++i)
    {
        vec3 current_position = ro + total_distance_traveled * rd;

        int index = 0;
        float distance_to_closest = distanceToClosest(current_position);

        if (distance_to_closest < MINIMUM_HIT_DISTANCE) 
        {
            vec3 normal = estimateNormal(current_position);
            return blinn_phong(current_position, rd, normal);
        }

        if (total_distance_traveled > MAXIMUM_TRACE_DISTANCE)
        {
            break;
        }
        total_distance_traveled += distance_to_closest;
    }
    return vec3(0.0);
}

float distanceToClosest(vec3 currPos) {
    float minv = 10000.0;
    for(int i = 0; i < SPHERES.length; i++) {
        float d = distance_from_sphere(currPos,SPHERES[i], 0.5);
        if(d < minv) {
            minv = d;
        }
    }
    minv = min(minv, distanceFromPlane(currPos));
    return minv;
}

//TODO add material properties
vec3 blinn_phong(vec3 currPos, vec3 viewDir, vec3 normal) {
    const float ambient = 0.4;
    const float diffuse = 0.8;
    const float specular = 1.0;

    vec3 ret = ambient*LIGHT_COLOR;
    ret += diffuse * LIGHT_COLOR * dot(normalize(LIGHT_POS - currPos), normal);
    vec3 dirToLight = normalize(LIGHT_POS - currPos);
    vec3 halfvec = normalize(dirToLight - viewDir);
    if(dot(halfvec, viewDir) > 0.)
        ret += pow(dot(halfvec, normal), specular) * LIGHT_COLOR;

    return ret;
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

    // camera	
    vec3 ta = vec3( 0.25, -0.75, -0.75 );
    vec3 ro = ta + vec3( 4.5*cos(0.1*u_Time + 7.0*mouse.x), 2.2, 4.5*sin(0.1*u_Time + 7.0*mouse.x) );
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );

    vec2 p = (2.0*fragCoord-u_Resolution.xy)/u_Resolution.y;

    // focal length
    const float fl = 2.5;
        
    // ray direction
    vec3 rd = ca * normalize( vec3(p,fl) );

    // ray differentials...
    vec2 px = (2.0*(fragCoord+vec2(1.0,0.0))-u_Resolution.xy)/u_Resolution.y;
    vec2 py = (2.0*(fragCoord+vec2(0.0,1.0))-u_Resolution.xy)/u_Resolution.y;
    vec3 rdx = ca * normalize( vec3(px,fl) );
    vec3 rdy = ca * normalize( vec3(py,fl) );
        

    vec3 shaded_color = ray_march(ro, rd);
    color = vec4(shaded_color, 1.0);
}
