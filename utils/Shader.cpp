#include "Shader.h"

#include <iostream>
#include <fstream>
#include <string>
#include <sstream>

#include "../utils/Renderer.h"


struct ShaderProgramSource {
	std::string VertexSource;
	std::string FragmentSource;
};


Shader::Shader(const std::string& fs, const std::string& vs)
	: m_RendererID(0) {
	ShaderProgramSource source = { ParseFile(fs), ParseFile(vs) };
	m_RendererID = CreateShader(source.VertexSource, source.FragmentSource);
}

Shader::~Shader() {
	glDeleteProgram(m_RendererID);
}

void Shader::Bind() const {
	glUseProgram(m_RendererID);
}

void Shader::Unbind() const {
	glUseProgram(0);
}

void Shader::SetUniform1i(const std::string& name, int v) {
	glUniform1i(GetUniformLocation(name), v);
}

void Shader::SetUniformMat4f(const std::string& name, const glm::mat4& matrix) {
	glUniformMatrix4fv(GetUniformLocation(name), 1, GL_FALSE, &matrix[0][0]);
}

void Shader::SetUniform4f(const std::string& name, float v0, float v1, float v2, float v3) {
	glUniform4f(GetUniformLocation(name), v0, v1, v2, v3);
}

void Shader::SetUniformVec3f(const std::string& name, glm::vec3 v) {
	glUniform3f(GetUniformLocation(name), v.x, v.y, v.z);
}

void Shader::SetUniform2f(const std::string& name, float v0, float v1) {
	glUniform2f(GetUniformLocation(name), v0, v1);
}

void Shader::SetUniform1f(const std::string& name, float v0) {
	glUniform1f(GetUniformLocation(name), v0);
}

//this could be done differently, 
int Shader::GetUniformLocation(const std::string& name) {
	auto ite = m_UniformLocationCache.find(name.c_str());
	if ( ite != m_UniformLocationCache.end()) 
		return ite->second;
	int location = glGetUniformLocation(m_RendererID, name.c_str());
	if (location == -1)
		std::cout << "Warning: uniform '" << name << "' doesn't exist" << std::endl;
	//TODO make this more efficient
	m_UniformLocationCache[name] = location;
	return location;
}

unsigned int Shader::CompileShader(unsigned int type, const std::string& source) {
	unsigned int id = glCreateShader(type);
	const char* src = source.c_str(); //same as &source[0]
	glShaderSource(id, 1, &src, nullptr);
	glCompileShader(id);

	int result;
	glGetShaderiv(id, GL_COMPILE_STATUS, &result); //check if succesful
	if (result == GL_FALSE) {
		int length;
		glGetShaderiv(id, GL_SHADER_SOURCE_LENGTH, &length);
		//char message[length] doesnt work but we still want this on the stack -> alloca
		//only a problem if we allocate too much and cause overflow
		char* message = (char*)alloca(length * sizeof(char));
		glGetShaderInfoLog(id, length, &length, message);
		std::cout << "Failed to compile shader\n" << source << std::endl;
		std::cout << message << std::endl;
	}

	return id;
}

unsigned int Shader::CreateShader(const std::string& vertexShader, const std::string& fragmentShader) {
	unsigned int program = glCreateProgram();
	unsigned int vs = CompileShader(GL_VERTEX_SHADER, vertexShader);
	unsigned int fs = CompileShader(GL_FRAGMENT_SHADER, fragmentShader);

	glAttachShader(program, vs);
	glAttachShader(program, fs);
	glLinkProgram(program);
	glValidateProgram(program);


	glDeleteShader(vs);
	glDeleteShader(fs);

	return program;
}

std::string Shader::ParseFile(const std::string& filePath) {
	std::ifstream file(filePath);
	std::string str;
	std::string content;
	while (std::getline(file, str)) {
		content.append(str + "\n");
	}
	return content;
}