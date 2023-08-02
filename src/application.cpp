#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include "../utils/debugging.h"

#include <iostream>
#include <fstream>
#include <string>
#include <sstream>

#include "../utils/IndexBuffer.h"
#include "../utils/VertexBuffer.h"
#include "../utils/VertexArray.h"



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

	glfwSwapInterval(1);


	
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


	unsigned int vao;
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);

	VertexArray va;
	VertexBuffer vb(positions, 4 * 2 * sizeof(float));
	VertexBufferLayout layout;
	layout.Push(GL_FLOAT, 2);
	va.AddBuffer(vb, layout);


	IndexBuffer ib(indices, 6);


	ShaderProgramSource source = ParseShader("res/shaders/basic.vert.glsl", "res/shaders/basic.frag.glsl");
	std::cout << source.FragmentSource << std::endl;
	std::cout << source.VertexSource << std::endl; 

	unsigned int shader = CreateShader(source.VertexSource, source.FragmentSource);
	glUseProgram(shader);

	int location = glGetUniformLocation(shader, "u_Color");
	glUniform4f(location, 0.2f, 0.3f, 0.8f, 1.0f);

	float r = 0.0f;
	float increment = 0.05f;

	/* Loop until the user closes the window */
	while (!glfwWindowShouldClose(window))
	{
		/* Render here */
		glClear(GL_COLOR_BUFFER_BIT);

		glUseProgram(shader);
		glUniform4f(location, r, 0.3f, 0.8f, 1.0f);

		va.Bind();
		ib.Bind();

		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, nullptr);


		glUniform4f(location, r, 0.3f, 0.8f, 1.0f);
		if (r > 1.0f) {
			increment = -0.05f;
		}
		else if (r < 0.0f) {
			increment = 0.05f;
		}
		r += increment;

		/* Swap front and back buffers */
		glfwSwapBuffers(window);

		/* Poll for and process events */
		glfwPollEvents();
	}

	glDeleteProgram(shader);

	glfwTerminate();
	return 0;
}