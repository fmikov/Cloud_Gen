#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include <iostream>
#include <fstream>
#include <string>
#include <sstream>


struct ShaderProgramSource {
	std::string VertexSource;
	std::string FragmentSource;
};

static std::string ParseFile(const std::string filePath) {
	std::ifstream file(filePath);
	std::string str;
	std::string content;
	while (std::getline(file, str)) {
		content.append(str + "\n");
	}
	return content;
}

static ShaderProgramSource ParseShader(const std::string& filepath) {
	std::ifstream stream(filepath);

	enum class ShaderType {
		NONE = -1, VERTEX = 0, FRAGMENT = 1
	};
	ShaderType type = ShaderType::NONE;

	std::string line;
	std::stringstream ss[2];
	while (getline(stream, line)) {
		if (line.find("#shader") != std::string::npos) {
			if (line.find("#vertex") != std::string::npos) {
				type = ShaderType::VERTEX;
			} else 
			if (line.find("#fragment") != std::string::npos) {
				type = ShaderType::FRAGMENT;
			}
		}
		//if not a shader identifier, add the line to the shader source code
		else {
			std::cout << (int)type << std::endl;
			ss[(int)type] << line << '\n';
		}
	}
	return { ss[0].str(), ss[1].str() };
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
		std::cout << "Failed to compile shader" << source << std::endl;
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


	float positions[6] = { -0.5f, -0.5,
							0.0f,  0.5f,
							0.5f, -0.5f
	};

	unsigned int buffer;
	glGenBuffers(1, &buffer);
	glBindBuffer(GL_ARRAY_BUFFER, buffer); //this bind causes the next drawArrays to use this buffer
	glBufferData(GL_ARRAY_BUFFER, 6 * sizeof(float), positions, GL_STATIC_DRAW);

	glEnableVertexAttribArray(0);
	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), 0);


	ShaderProgramSource source = ParseShader("res/shaders/Basic.shader");
	std::cout << source.FragmentSource << std::endl;
	std::cout << source.VertexSource << std::endl; 

	unsigned int shader = CreateShader(source.VertexSource, source.FragmentSource);
	glUseProgram(shader);

	/* Loop until the user closes the window */
	while (!glfwWindowShouldClose(window))
	{
		/* Render here */
		glClear(GL_COLOR_BUFFER_BIT);

		glDrawArrays(GL_TRIANGLES, 0, 3);

		/* Swap front and back buffers */
		glfwSwapBuffers(window);

		/* Poll for and process events */
		glfwPollEvents();
	}

	glDeleteProgram(shader);

	glfwTerminate();
	return 0;
}