#version 330 core

layout(location = 0) out vec4 color;

uniform sampler2D u_Texture;
uniform vec2 u_Resolution;

in vec2 v_TexCoord;

const int NUMBER_OF_STEPS = 32;
const float MINIMUM_HIT_DISTANCE = 0.001;
const float MAXIMUM_TRACE_DISTANCE = 1000.0;


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

        float distance_to_closest = distance_from_sphere(current_position, vec3(0.0, 0.0, 0.0), 0.5);

        if (distance_to_closest < MINIMUM_HIT_DISTANCE) 
        {
            return vec3(1.0, 0.0, 0.0);
        }

        if (total_distance_traveled > MAXIMUM_TRACE_DISTANCE)
        {
            break;
        }
        total_distance_traveled += distance_to_closest;
    }
    return vec3(0.0);
}

void main() {
	//vec4 texColor = texture(u_Texture, v_TexCoord);
	//color = texColor;

    vec2 uv = (gl_FragCoord.xy-.5*u_Resolution.xy)/u_Resolution.y;
     

    vec3 camera_position = vec3(0.0, 0.0, -3.0);
    vec3 ro = camera_position;
    vec3 rd = vec3(uv, 1.0);

    vec3 shaded_color = ray_march(ro, rd);

    color = vec4(uv.x, uv.y, shaded_color.x, 1.0);
}
