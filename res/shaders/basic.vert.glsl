#version 330 core

layout(location = 0) in vec4 position;
layout(location = 1) in vec2 texCoord;

out vec2 v_TexCoord;

uniform mat4 u_MVP;

void main() {
	gl_Position = vec4(position.xy, 0.0, 1.0);
	v_TexCoord = texCoord;
}


