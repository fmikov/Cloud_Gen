#version 330 core

layout(location = 0) in vec2 position;
layout(location = 1) in vec2 texCoord;

out vec2 v_TexCoord;
out vec3 v_Position;


uniform mat4 u_MVP;

void main() {
    v_Position = vec3(position.xy, 0.0);

	gl_Position = u_MVP * vec4(position, 1.0, 1.0);
	v_TexCoord = texCoord;
}