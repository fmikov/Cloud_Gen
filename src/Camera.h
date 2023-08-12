#pragma once
#include "glm.hpp"
#include "ext/matrix_transform.hpp"
#include "GLFW/glfw3.h"

using namespace glm;

class Camera
{
private:
	vec3 m_CameraTarget;
	vec3 m_CameraPos = vec3(0.f, 0.f, -3.f);
	vec3 m_CameraUp;
	vec3 m_CameraRight;
	vec3 m_GlobalUp = vec3(0.f, 1.f, 0.f);
	double m_AngleY;
	double m_AngleZ;
	//angles
	float m_Pitch = 0.0f;
	float m_Yaw =  - 90.0f;
	// camera options
	float MovementSpeed;
	float MouseSensitivity;
	float m_FOV;

	void UpdateCameraVectors();

	
public:
	Camera(const vec3& tar, float fov = radians(45.f));
	~Camera();

	mat4 GetLookAtMatrix();
	mat4 GetWalkMatrix();
	mat4 GetPerspectiveMatrix();

	void ProcessKeyboard();
	void ProcessMouseScroll(float yoffset);
	void ProcessMouseMovement(float xoffset, float yoffset);
	
};

void processInput(GLFWwindow* window);