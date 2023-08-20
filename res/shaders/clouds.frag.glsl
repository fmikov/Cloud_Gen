#version 330 core

layout(location = 0) out vec4 color;

uniform sampler2D u_Texture;
uniform vec2 u_Resolution;
uniform vec3 u_CameraPos;
uniform vec3 u_CameraFront;
uniform vec3 u_CameraRight;

in vec2 v_TexCoord;

const int NUMBER_OF_STEPS = 32;
const float MINIMUM_HIT_DISTANCE = 0.001;
const float MAXIMUM_TRACE_DISTANCE = 1000.0;

const vec3 LIGHT_POS = vec3(3.0, 3.0, 4.0);
const vec3 SPHERES[3] = vec3[](vec3(0.5, 0.5, 0.0), vec3(2.0, 1.0, 2.0), vec3(3.0, 5.0, 3.0));
const vec3 LIGHT_COLOR = vec3(1.0, 1.0, 0.0);
const vec3 SPHERE_POS = vec3(0.5, 0.5, 0.0);

vec3 getNormalSphere(vec3 currPos, vec3 center);
vec3 blinn_phong(vec3 currPos, vec3 viewDir, vec3 normal);
float distanceToClosestSphere(vec3 currPos, out int index);

float distance_from_sphere(in vec3 p, in vec3 c, float r)
{
    return length(p - c) - r;
}

vec3 ray_march(in vec3 ro, in vec3 rd)
{
    float total_distance_traveled = 0.0;
 
    for (int i = 0; i < NUMBER_OF_STEPS; ++i)
    {
        vec3 current_position = ro + total_distance_traveled * rd;

        int index = 0;
        float distance_to_closest = distanceToClosestSphere(current_position, index);

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

float distanceToClosestSphere(vec3 currPos, out int index) {
    float min = 10000.0;
    for(int i = 0; i < SPHERES.length; i++) {
        float d = distance_from_sphere(currPos,SPHERES[i], 0.5);
        if(d < min) {
            min = d;
            index = i;
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
	//vec4 texColor = texture(u_Texture, v_TexCoord);
	//color = texColor;

    //vec2 uv = (gl_FragCoord.xy-.5*u_Resolution.xy)/u_Resolution.y;
    vec2 uv=gl_FragCoord.xy/u_Resolution.xy;
    uv-=vec2(0.5);//offset, so center of screen is origin
    uv.x*=u_Resolution.x/u_Resolution.y;//scale, so there is no rectangular distortion

    //vec3 ro = u_CameraPos + normalize((vec3(uv, 1.0) * (u_CameraRight)));
    //vec3 rd = u_CameraFront;

    vec3 camera_position = vec3(0.0, 0.0, -4.0);
    vec3 ro = u_CameraPos;
    vec3 rd = normalize(vec3(uv, 1.0));

    vec3 shaded_color = ray_march(ro, rd);

    color = vec4(u_CameraFront - shaded_color, 1.0);
}
