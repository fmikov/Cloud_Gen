#version 330 core
out vec2 v_TexCoord;
out vec4 near_4;   
out vec4 far_4;

out vec3 origin;
out vec3 ray_dir;

layout (location = 0) in vec2 pos;

uniform float u_Aspect;
uniform vec2 u_Resolution;
uniform mat4 u_MVP;
uniform mat4 u_MVP_inverse;

void main() {
    gl_Position = vec4(pos, 0.0, 1.0);       
}