#pragma once
#include "glm.hpp"
#include "ext/matrix_transform.hpp"
#include "GLFW/glfw3.h"
#include "Global.h"
#include "ext/matrix_clip_space.hpp"

using namespace glm;

class Camera
{
private:
	vec3 m_CameraFront;
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
	float m_MovementSpeed = 5.f;
	float m_MouseSensitivity = 0.1f;

private:
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

	[[nodiscard]] vec3 m_camera_front() const
	{
		return m_CameraFront;
	}

	[[nodiscard]] vec3 m_camera_pos() const
	{
		return m_CameraPos;
	}

	[[nodiscard]] vec3 m_camera_up() const
	{
		return m_CameraUp;
	}

	[[nodiscard]] vec3 m_camera_right() const
	{
		return m_CameraRight;
	}

	[[nodiscard]] float m_pitch() const
	{
		return m_Pitch;
	}

	[[nodiscard]] float m_yaw() const
	{
		return m_Yaw;
	}
};

void processInput(GLFWwindow* window);