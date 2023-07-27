#shader vertex
#version 330 core	
void main() {
	gl_Position = position;
}
#shader fragment
#version 330 core
layout(location = 0) out vec4 color;
void main() {
	color = vec4(1.0, 1.0, 0.0, 0.0);
}