#version 330 core
#include "shader_includes/noise.glsl"

layout(location = 0) out vec4 color;

uniform vec4 u_Color;
uniform sampler2D u_Texture;

in vec2 v_TexCoord;
in vec3 v_Position;


void main() {
	//vec4 texColor = texture(u_Texture, v_TexCoord);
	//float pnoise = noise(vec3(v_TexCoord, 1.0));
	float stratus = remap(v_TexCoord.y, 0.0, 0.1, 0.0, 1.0) * remap(v_TexCoord.y, 0.2, 0.3, 1.0, 0.0);
	float worley = worley(v_TexCoord);
	vec3 idk = v_TexCoord.y > 0.? vec3(1.0) : vec3(0.0);
	color = vec4(vec3(v_TexCoord.y), 1.0);
}