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


in vec4 near_4;   
in vec4 far_4;
in vec2 v_TexCoord;
in vec3 origin;
in vec3 ray_dir;

const int NUMBER_OF_STEPS = 32;
const float MINIMUM_HIT_DISTANCE = 0.001;
const float MAXIMUM_TRACE_DISTANCE = 1000.0;

const vec3 LIGHT_POS = vec3(3.0, 3.0, 4.0);
const vec3 SPHERES[3] = vec3[](vec3(0.0, 0.0, -2.0), vec3(2.0, 1.0, 2.0), vec3(3.0, 5.0, 3.0));
const vec3 LIGHT_COLOR = vec3(1.0, 1.0, 0.0);
const vec3 SPHERE_POS = vec3(0.5, 0.5, 0.0);

struct ray {
    vec3 pos;
    vec3 dir;
};

vec3 getNormalSphere(vec3 currPos, vec3 center);
vec3 blinn_phong(vec3 currPos, vec3 viewDir, vec3 normal);
float distanceToClosestSphere(vec3 currPos);

float distance_from_sphere(in vec3 p, in vec3 c, float r)
{
    return length(p - c) - r;
}

//Estimate normal 
const float EPS=0.001;
vec3 estimateNormal(vec3 p){
    float xPl=distanceToClosestSphere(vec3(p.x+EPS,p.y,p.z));
    float xMi=distanceToClosestSphere(vec3(p.x-EPS,p.y,p.z));
    float yPl=distanceToClosestSphere(vec3(p.x,p.y+EPS,p.z));
    float yMi=distanceToClosestSphere(vec3(p.x,p.y-EPS,p.z));
    float zPl=distanceToClosestSphere(vec3(p.x,p.y,p.z+EPS));
    float zMi=distanceToClosestSphere(vec3(p.x,p.y,p.z-EPS));
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
        float distance_to_closest = distanceToClosestSphere(current_position);

        if (distance_to_closest < MINIMUM_HIT_DISTANCE) 
        {
            vec3 normal = getNormalSphere(current_position, SPHERES[index]);
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

float distanceToClosestSphere(vec3 currPos) {
    float min = 10000.0;
    for(int i = 0; i < SPHERES.length; i++) {
        float d = distance_from_sphere(currPos,SPHERES[i], 0.5);
        if(d < min) {
            min = d;
        }
    }
    return min;
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

vec3 getNormalSphere(vec3 currPos, vec3 center){
    vec3 ret = normalize(center - currPos);
    return ret;
}

void main() {
    //vec2 uv=gl_FragCoord.xy/u_Resolution.xy;
    //uv-=vec2(0.5);//offset, so center of screen is origin
    //uv.x*=u_Resolution.x/u_Resolution.y;//scale, so there is no rectangular distortion

    //vec3 ro = u_CameraPos + normalize((vec3(uv, 1.0) * (u_CameraRight)));
    //vec3 rd = u_CameraFront;


    //vec3 camera_position = vec3(0.0, 0.0, -4.0);
    //vec3 ro = u_CameraPos;
    //vec3 rd = normalize(vec3(uv, 1.0));

    vec2 screen_pos = (gl_FragCoord.xy) / u_Resolution.xy;
    vec2 uv = 2*screen_pos - 1;
    uv.x *= u_Aspect;
 
    vec3 origin = near_4.xyz/near_4.w;  //ray's origin
    vec3 far3 = far_4.xyz/far_4.w;
    vec3 dir = far3 - origin;
    dir = normalize(dir);
    vec3 shaded_color = ray_march(origin, normalize(dir));


    float FOCAL_DIST = 1.73205080757;
    vec3 ro = u_MVP[3].xyz;
    vec4 tmp = vec4(uv, 1.0, 1.0);
    vec3 rd = normalize((u_MVP_inverse * tmp).xyz);
    rd = normalize(rd - ro);
    //rd = normalize((u_MVP * vec4(uv, FOCAL_DIST, 0.0)).xyz);
    shaded_color = ray_march(ro, rd);
    color = vec4(shaded_color, 1.0);
}
