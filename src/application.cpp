#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include "../utils/Debugging.h"

#include <iostream>
#include <fstream>
#include <string>
#include <sstream>

#include "Camera.h"
#include "CameraInputHandler.h"
#include "Texture.h"
#include "IndexBuffer.h"
#include "VertexBuffer.h"
#include "VertexArray.h"
#include "Shader.h"
#include "Renderer.h"

#include "glm/glm.hpp"
#include "glm/gtc/matrix_transform.hpp"
#include "imgui/imgui.h"
#include "imgui/imgui_impl_glfw.h"
#include "imgui/imgui_impl_opengl3.h"

#include "Global.h"
#include "gtc/matrix_inverse.hpp"


int main(void)
{
	GLFWwindow* window;

	/* Initialize the library */
	if (!glfwInit())
		return -1;

	/* init debug context*/
	glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GL_TRUE);

	/* Create a windowed mode window and its OpenGL context */
	const vec2 RESOLUTION = { 1920.f, 1080.f };
	window = glfwCreateWindow(RESOLUTION.x, RESOLUTION.y, "Hello World", NULL, NULL);
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


	float positions[] = {
		-1.0f, -1.0f,
		 1.0f, -1.0f,
		 1.0f,  1.0f,
		-1.0f,  1.0f,
	};

	unsigned int indices[]{
		0, 1, 2,
		2, 3, 0
	};

	//setup blending
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	unsigned int vao;
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);

	VertexArray va;
	VertexBuffer vb(positions, 4 * 2 * sizeof(float));
	VertexBufferLayout layout;
	layout.Push(GL_FLOAT, 2);
	va.AddBuffer(vb, layout);

	IndexBuffer ib(indices, 6);


	//visualization objects, will use basic shader
	float positions2[] = {
		-0.5f, -0.5f, 0.0f, 0.0f,
		 0.5f, -0.5f, 1.0f, 0.0f,
		 0.5f,  0.5f, 1.0f, 1.0f,
		-0.5f,  0.5f, 0.0f, 1.0f
	};

	unsigned int indices2[]{
		0, 1, 2,
		2, 3, 0
	};

	VertexArray va2;
	VertexBuffer vb2(positions2, 4 * 4 * sizeof(float));
	VertexBufferLayout layout2;
	layout2.Push(GL_FLOAT, 2);
	layout2.Push(GL_FLOAT, 2);
	va2.AddBuffer(vb2, layout2);

	IndexBuffer ib2(indices2, 6);
	//end visualization setup



	//converts into [-1, -1] range
	//glm::mat4 proj = glm::ortho(-2.0f, 2.0f, -1.5f, 1.5f, -1.0f, 1.0f);
	mat4 proj = perspective(radians(45.0f), RESOLUTION.x/RESOLUTION.y, 0.0f, 100.0f);
	mat4 view = glm::translate(glm::mat4(0.0f), glm::vec3(0.0f, 0.0f, 4.0f)); //camera
	mat4 model = mat4(1.f);

	mat4 mvp = proj * view * model;

	
	Shader shader_march = { "res/shaders/raymarch.vert.glsl", "res/shaders/clouds.frag.glsl" };
	shader_march.Bind();
	shader_march.SetUniform1f("u_Aspect", RESOLUTION.x / RESOLUTION.y);
	shader_march.SetUniform2f("u_Resolution", RESOLUTION.x, RESOLUTION.y);

	Shader shader = { "res/shaders/basic.vert.glsl", "res/shaders/basic.frag.glsl" };
	shader.Bind();
	shader.SetUniform4f("u_Color", 0.2f, 0.3f, 0.8f, 1.0f);



	va.Unbind();
	ib.Unbind();
	vb.Unbind();
	shader_march.Unbind();

	// --------------------------------------------- imgui setup
	IMGUI_CHECKVERSION();
	ImGui::CreateContext();
	ImGui_ImplGlfw_InitForOpenGL(window, true);
	ImGui::StyleColorsDark();
	ImGui_ImplOpenGL3_Init("#version 330");
	ImGuiIO& io = ImGui::GetIO(); (void)io;
	io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
	io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;

	ImGui::StyleColorsDark();

	bool show_demo_window = false;
	bool show_another_window = false;
	ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);

	// ----------------------------------------------


	Renderer renderer;
	view = camera.GetLookAtMatrix();
	proj = camera.GetPerspectiveMatrix();


	//input
	glfwSetCursorPosCallback(window, CameraInputHandler::MousePositionCallback);
	glfwSetScrollCallback(window, CameraInputHandler::MouseScrollCallback);
	glfwSetKeyCallback(window, CameraInputHandler::KeyboardMovementCallback);


	/* Loop until the user closes the window */
	while (!glfwWindowShouldClose(window))
	{
		/* Render here */
		renderer.Clear();

		ImGui_ImplOpenGL3_NewFrame();
		ImGui_ImplGlfw_NewFrame();
		ImGui::NewFrame();

		currFrame = glfwGetTime();
		deltaTime = currFrame - lastFrame;
		lastFrame = currFrame;

		
		//process keyboard input for camera
		camera.ProcessKeyboard();

		view = camera.GetWalkMatrix();
		proj = camera.GetPerspectiveMatrix();

		mvp = proj * view * model; //multiplication right to left

		shader_march.Bind();
		shader_march.SetUniformMat4f("u_MVP", mvp);
		shader_march.SetUniformMat4f("u_MVP_inverse", glm::inverse(proj*view));
		shader_march.SetUniformVec3f("u_CameraPos", camera.m_camera_pos());
		shader_march.SetUniformVec3f("u_CameraFront", camera.m_camera_front());
		shader_march.SetUniformVec3f("u_CameraRight", camera.m_camera_right());
		shader_march.SetUniformVec3f("u_CameraUp", camera.m_camera_up());
		shader_march.SetUniform1f("u_Time", currFrame);

		shader_march.SetUniform2f("u_PitchYaw", radians(camera.m_pitch()), radians(camera.m_yaw()));

		renderer.Draw(va, ib, shader_march);

		//visualization renderer
		shader.Bind();
		shader.SetUniformMat4f("u_MVP", mvp);
		shader.SetUniform1f("u_Time", currFrame);
		renderer.Draw(va2, ib2, shader);



		

		

		if (show_demo_window)
			ImGui::ShowDemoWindow(&show_demo_window);
		{
			static float f = 0.0f;
			static int counter = 0;

			ImGui::Begin("Hello, world!");                          // Create a window called "Hello, world!" and append into it.

			ImGui::Text("This is some useful text.");               // Display some text (you can use a format strings too)
			ImGui::Checkbox("Demo Window", &show_demo_window);      // Edit bools storing our window open/close state
			ImGui::Checkbox("Another Window", &show_another_window);

			ImGui::SliderFloat("float", &f, 0.0f, 1.0f);
			ImGui::ColorEdit3("clear color", (float*)&clear_color);

			if (ImGui::Button("Button"))                            // Buttons return true when clicked (most widgets return true when edited/activated)
				counter++;
			ImGui::SameLine();
			ImGui::Text("counter = %d", counter);

			ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / io.Framerate, io.Framerate);
			ImGui::End();
		}

		ImGui::Render();
		//int display_w, display_h;
		//glfwGetFramebufferSize(window, &display_w, &display_h);
		//glViewport(0, 0, display_w, display_h);
		//glClearColor(clear_color.x * clear_color.w, clear_color.y * clear_color.w, clear_color.z * clear_color.w, clear_color.w);
		//glClear(GL_COLOR_BUFFER_BIT);
		ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());


		/* Swap front and back buffers */
		glfwSwapBuffers(window);

		/* Poll for and process events */
		glfwPollEvents();
	}

	ImGui_ImplOpenGL3_Shutdown();
	ImGui_ImplGlfw_Shutdown();
	ImGui::DestroyContext();

	glfwTerminate();
	return 0;
}
