#version 330 core
out vec2 v_TexCoord;

uniform float u_Aspect;
uniform vec2 u_Resolution;
uniform mat4 u_MVP;

void main() {
	v_TexCoord = vec2(((gl_VertexID << 1) & 2) << 1, (gl_VertexID & 2) << 1); // 0, 0 ; 2, 0 ; 0, 2 using fullscreen triangle
	//v_TexCoord.x *= u_Aspect;
	gl_Position = vec4(v_TexCoord * vec2(2.0f, -2.0f) + vec2(-1.0f, 1.0f), 0.0f, 1.0f);

}