#pragma once
#include "glm.hpp"
#include "ext/matrix_transform.hpp"
#include "GLFW/glfw3.h"

using namespace glm;

class Camera
{
private:
	vec3 m_CameraTarget;
	double m_AngleY;
	double m_AngleZ;
public:
	Camera(const vec3& tar);
	~Camera();

	mat4 GetLookAtMatrix();

	
};
