#pragma once
#include "Camera.h"
#include "GLFW/glfw3.h"
#include "Global.h"

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
};
