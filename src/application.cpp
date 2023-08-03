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
#include "../utils/Shader.h"
#include "../utils/Renderer.h"

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

	Shader shader = { "res/shaders/basic.vert.glsl", "res/shaders/basic.frag.glsl" };
	shader.Bind();
	shader.SetUniform4f("u_Color", 0.2f, 0.3f, 0.8f, 1.0f);

	float r = 0.0f;
	float increment = 0.05f;

	Renderer renderer;

	/* Loop until the user closes the window */
	while (!glfwWindowShouldClose(window))
	{
		/* Render here */
		renderer.Clear();

		renderer.Draw(va, ib, shader);


		shader.Bind();
		shader.SetUniform4f("u_Color", r, 0.3f, 0.8f, 1.0f);
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

	glfwTerminate();
	return 0;
}