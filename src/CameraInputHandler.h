#pragma once
#include "Camera.h"
#include "GLFW/glfw3.h"
#include "Global.h"

Camera camera(vec3(0.f, 0.f, 0.f));
namespace CameraInputHandler
{

    double xPrev;
    double yPrev;
    bool firstMouseMovement = true;
    void MousePositionCallback(GLFWwindow* window, double xpos, double ypos) {
        bool lButtonDown = false;
        int mouseAction = glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT);
        if (mouseAction == GLFW_PRESS) {
            lButtonDown = true;
        }
        if (mouseAction == GLFW_RELEASE) {
            lButtonDown = false;
            xPrev = xpos;
            yPrev = ypos;
        }
        if (firstMouseMovement)
        {
            xPrev = xpos;
            yPrev = ypos;
            firstMouseMovement = false;
        }
        if(lButtonDown)
        {
	        float xoffset = xpos - xPrev;
	        float yoffset = yPrev - ypos; // reversed since y-coordinates range from bottom to top
	        xPrev = xpos;
	        yPrev = ypos;
	        camera.ProcessMouseMovement(xoffset, yoffset);
        }
    }

    void MouseScrollCallback(GLFWwindow* window, double xoffset, double yoffset)
    {
        camera.ProcessMouseScroll(static_cast<float>(yoffset));
    }

    void KeyboardMovementCallback(GLFWwindow* window, int key, int scancode, int action, int mods)
    {
        if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        {
            KEY_MAP[GLFW_KEY_ESCAPE] = true;
			glfwSetWindowShouldClose(window, true);
        }

        if (action == GLFW_PRESS)
        {
            KEY_MAP[key] = true;
        }
        if (action == GLFW_RELEASE)
        {
            KEY_MAP[key] = false;
        }
    }
};
