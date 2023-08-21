#version 330 core
out vec2 v_TexCoord;
out vec4 near_4;   
out vec4 far_4;

layout (location = 0) in vec2 position;

uniform float u_Aspect;
uniform vec2 u_Resolution;
uniform mat4 u_MVP;
uniform mat4 u_MVP_inverse;

void main() {
	//v_TexCoord = vec2(((gl_VertexID << 1) & 2) << 1, (gl_VertexID & 2) << 1); // 0, 0 ; 2, 0 ; 0, 2 using fullscreen triangle
	//v_TexCoord.x *= u_Aspect;
	//gl_Position = vec4(v_TexCoord * vec2(2.0f, -2.0f) + vec2(-1.0f, 1.0f), 0.0f, 1.0f);

	//gl_Position = u_MVP * position;       

    //get 2D projection of this vertex in normalized device coordinates
    //vec2 pos = gl_Position.xy/gl_Position.w;
   
    //compute ray's start and end as inversion of this coordinates
    //in near and far clip planes
    //near_4 = u_MVP_inverse * (vec4(pos, -1.0, 1.0));       
    //far_4 = u_MVP_inverse * (vec4(pos, +1.0, 1.0));

    gl_Position = vec4(position, -1.0, 1.0);
	v_TexCoord = position * 0.5 + 0.5; 


}