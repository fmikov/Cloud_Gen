#pragma once

#include <GL/glew.h>
#include <GLFW/glfw3.h>


#define ASSERT(x) if (!(x)) __debugbreak();

void APIENTRY glDebugOutput(GLenum source, GLenum type, unsigned int id, GLenum severity,
    GLsizei length, const char* message, const void* userParam);

void setupDebugContext();
