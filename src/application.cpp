#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include "../utils/debugging.h"

#include <iostream>
#include <fstream>
#include <string>
#include <sstream>



struct ShaderProgramSource {
	std::string VertexSource;
	std::string FragmentSource;
};

static std::string ParseFile(const std::string& filePath) {
	std::ifstream file(filePath);
	std::string str;
	std::string content;
	while (std::getline(file, str)) {
		content.append(str + "\n");
	}
	return content;
}

static ShaderProgramSource ParseShader(const std::string& vertexPath, const std::string& fragmentPath) {
	return { ParseFile(vertexPath), ParseFile(fragmentPath) };
}
													//can use std::string_view instead HOWEVER not guaranteed to be null terminated
static unsigned int CompileShader(unsigned int type, const std::string& source) {
	unsigned int id = glCreateShader(type);
	const char* src = source.c_str(); //same as &source[0]
	glShaderSource(id, 1, &src, nullptr);
	glCompileShader(id);

	int result;
	glGetShaderiv(id, GL_COMPILE_STATUS, &result); //check if succesful
	if (result == GL_FALSE) {
		int length;
		glGetShaderiv(id, GL_SHADER_SOURCE_LENGTH, &length);
		//char message[length] doesnt work but we still want this on the stack -> alloca
		//only a problem if we allocate too much and cause overflow
		char* message = (char*) alloca(length * sizeof(char));
		glGetShaderInfoLog(id, length, &length, message);
		std::cout << "Failed to compile shader\n" << source << std::endl;
		std::cout << message << std::endl;
	}

	return id;
}

static unsigned int CreateShader(const std::string& vertexShader, const std::string& fragmentShader) {
	unsigned int program = glCreateProgram();
	unsigned int vs = CompileShader(GL_VERTEX_SHADER, vertexShader);
	unsigned int fs = CompileShader(GL_FRAGMENT_SHADER, fragmentShader);

	glAttachShader(program, vs);
	glAttachShader(program, fs);
	glLinkProgram(program);
	glValidateProgram(program);


	glDeleteShader(vs);
	glDeleteShader(fs);



	return program;
}

int main(void)
{
	GLFWwindow* window;

	/* Initialize the library */
	if (!glfwInit())
		return -1;

	/* init debug context*/
	glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GL_TRUE);

	/* Create a windowed mode window and its OpenGL context */
	window = glfwCreateWindow(640, 480, "Hello World", NULL, NULL);
	if (!window)
	{
		glfwTerminate();
		return -1;
	}
	

	/* Make the window's context current */
	glfwMakeContextCurrent(window);


	
	if (glewInit() != GLEW_OK)
		std::cout << "Error!" << std::endl;

	std::cout << glGetString(GL_VERSION) << std::endl;

	//setting up debug context
	setupDebugContext();



	float positions[] = {  -0.5f, -0.5f,
							0.5f, -0.5f,
							0.5f,  0.5f,
						   -0.5f,  0.5f				
	};

	unsigned int indices[]{
		0, 1, 2,
		2, 3, 0
	};

	unsigned int buffer;
	glGenBuffers(1, &buffer);
	glBindBuffer(GL_ARRAY_BUFFER, buffer); //this bind causes the next drawArrays to use this buffer
	glBufferData(GL_ARRAY_BUFFER, 8 * sizeof(float), positions, GL_STATIC_DRAW);

	glEnableVertexAttribArray(0);
	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), 0);

	unsigned int ibo;
	glGenBuffers(1, &ibo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, 6 * sizeof(unsigned int), indices, GL_STATIC_DRAW);


	ShaderProgramSource source = ParseShader("res/shaders/Vertex.shader", "res/shaders/Fragment.shader");
	std::cout << source.FragmentSource << std::endl;
	std::cout << source.VertexSource << std::endl; 

	unsigned int shader = CreateShader(source.VertexSource, source.FragmentSource);
	glUseProgram(shader);

	/* Loop until the user closes the window */
	while (!glfwWindowShouldClose(window))
	{
		/* Render here */
		glClear(GL_COLOR_BUFFER_BIT);

		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, nullptr);

		/* Swap front and back buffers */
		glfwSwapBuffers(window);

		/* Poll for and process events */
		glfwPollEvents();
	}

	glDeleteProgram(shader);

	glfwTerminate();
	return 0;
}