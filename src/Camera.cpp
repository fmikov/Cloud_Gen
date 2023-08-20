#include "Camera.h"

Camera::Camera(const vec3& tar, float fov)
    : m_CameraFront(tar), m_FOV(fov) {
    UpdateCameraVectors();
}

Camera::~Camera() {
}

mat4 Camera::GetLookAtMatrix()
{
    //TODO update with camera input handler and class variables changed
	const float radius = 10.0f;
	float camX = sin(glfwGetTime()) * radius;
	float camZ = cos(glfwGetTime()) * radius;
    vec3 eye = vec3(camX, 0.0, camZ);
	vec3 up = vec3(0.0f, 1.0f, 0.0f); //global up vector just for cross product
    //How the LookAt matrix calculations are done, in short:
	 // vec3 cameraDir = normalize(m_CameraFront - eye);
	 // vec3 cameraRight = normalize(cross(up, cameraDir));
	 // vec3 cameraUp = cross(cameraDir, cameraRight);
	 // mat4 view = mat4(cameraRight.x, cameraRight.y, cameraRight.z, -dot(cameraRight, eye),
	 //        cameraUp.x, cameraUp.y, cameraUp.z, -dot(cameraUp, eye),
	 //        -cameraDir.x, -cameraDir.y, -cameraDir.z, dot(cameraDir, eye),
	 //        0.f, 0.f, 0.f, 1.f);
	 //
	 // view = transpose(view);
	mat4 view = lookAt(eye,m_CameraFront, up);
    return view;
}


mat4 Camera::GetWalkMatrix()
{
	// direction.x = cos(glm::radians(m_Yaw)) * cos(glm::radians(m_Pitch));
	// direction.y = sin(glm::radians(m_Pitch));
	// direction.z = sin(glm::radians(m_Yaw)) * cos(glm::radians(m_Pitch));
    // vec3 cameraFront = normalize(m_CameraFront);
    mat4 view = glm::lookAt(m_CameraPos, m_CameraPos - m_CameraFront, m_GlobalUp);  
    return view;
}

mat4 Camera::GetPerspectiveMatrix()
{
    mat4 projection = glm::perspective(m_FOV, (float)1920 / (float)1080, 0.0f, 100.0f);
    return projection;

}



void Camera::ProcessKeyboard()
{
    float velocity = m_MovementSpeed * deltaTime;
    //wasd
    if (KEY_MAP[GLFW_KEY_W])
        m_CameraPos -= m_CameraFront * velocity;
    if (KEY_MAP[GLFW_KEY_S])
        m_CameraPos += m_CameraFront * velocity;
    if (KEY_MAP[GLFW_KEY_A])
        m_CameraPos += m_CameraRight * velocity;
    if (KEY_MAP[GLFW_KEY_D])
        m_CameraPos -= m_CameraRight * velocity;
    //up down
    if (KEY_MAP[GLFW_KEY_Q])
        m_CameraPos -= m_CameraUp * velocity;
    if (KEY_MAP[GLFW_KEY_E])
        m_CameraPos += m_CameraUp * velocity;
}

void Camera::ProcessMouseMovement(float xoffset, float yoffset)
{
    m_Yaw += xoffset * m_MouseSensitivity;
    m_Pitch -= yoffset * m_MouseSensitivity;

    //constrain to at most look directly down and up, prevents lookAt matrix flip and weird camera positions.
    if (m_Pitch > 89.0f)
        m_Pitch = 89.0f;
    if (m_Pitch < -89.0f)
        m_Pitch = -89.0f;
    UpdateCameraVectors();
}

void Camera::ProcessMouseScroll(float yoffset)
{
    m_FOV -= yoffset*0.2f;
    if (m_FOV < 1.0f)
        m_FOV = 1.0f;
    if (m_FOV > 45.0f)
        m_FOV = 45.0f;
}

void Camera::UpdateCameraVectors()
{
    m_CameraFront.x = cos(glm::radians(m_Yaw)) * cos(glm::radians(m_Pitch));
    m_CameraFront.y = sin(glm::radians(m_Pitch));
    m_CameraFront.z = sin(glm::radians(m_Yaw)) * cos(glm::radians(m_Pitch));
    m_CameraFront = glm::normalize(m_CameraFront);
    // also re-calculate the Right and Up vector
    m_CameraRight = glm::normalize(glm::cross(m_CameraFront, m_GlobalUp));  // normalize the vectors, because their length gets closer to 0 the more you look up or down which results in slower movement.
    m_CameraUp = glm::normalize(glm::cross(m_CameraRight, m_CameraFront));
	
}
