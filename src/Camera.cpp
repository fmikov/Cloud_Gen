#include "Camera.h"

#include <iostream>

#include "gtc/matrix_access.hpp"


double camAngleZ, camAngleY;
void CursorPositionCallback(GLFWwindow* window, double xPos, double yPos) {
    static double xPrev = 0, yPrev = 0;
    bool lButtonDown = false;
    int mouseAction = glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT);
    if (mouseAction == GLFW_PRESS) {
        lButtonDown = true;
    }
    if(mouseAction == GLFW_RELEASE) {
        lButtonDown = false;
    }


    // if(lButtonDown) {
    //     if (lButtonDown) {
    //         frame_info.cam_angle_z += event.movementX * 0.005
    //             frame_info.cam_angle_y += -event.movementY * 0.005
    //
    //             update_cam_transform(frame_info)
    //     }
    // }
	
}

Camera::Camera(const vec3& tar)
    : m_CameraTarget(tar) {
	
}

Camera::~Camera() {
}

mat4 Camera::GetLookAtMatrix()
{
	const float radius = 10.0f;
	float camX = sin(glfwGetTime()) * radius;
	float camZ = cos(glfwGetTime()) * radius;
    vec3 eye = vec3(camX, 0.0, camZ);
	vec3 up = vec3(0.0f, 1.0f, 0.0f); //global up vector just for cross product
    //How the LookAt matrix calculations are done, in short:
	 // vec3 cameraDir = normalize(m_CameraTarget - eye);
	 // vec3 cameraRight = normalize(cross(up, cameraDir));
	 // vec3 cameraUp = cross(cameraDir, cameraRight);
	 // mat4 view = mat4(cameraRight.x, cameraRight.y, cameraRight.z, -dot(cameraRight, eye),
	 //        cameraUp.x, cameraUp.y, cameraUp.z, -dot(cameraUp, eye),
	 //        -cameraDir.x, -cameraDir.y, -cameraDir.z, dot(cameraDir, eye),
	 //        0.f, 0.f, 0.f, 1.f);
	 //
	 // view = transpose(view);
	mat4 view = lookAt(eye,m_CameraTarget, up);
    return view;
}
