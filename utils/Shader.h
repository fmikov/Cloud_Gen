#pragma once
#include <string>
#include <unordered_map>

class Shader {
private:
	//std::string m_Filepath;
	unsigned int m_RendererID;
	//caching for uniforms
	std::unordered_map<std::string, int> m_UniformLocationCache;

public:
	Shader(const std::string& fs, const std::string& vs);
	~Shader();

	void Bind() const;
	void Unbind() const;

	//set uniforms
	void SetUniform4f(const std::string& name, float v0, float v1, float v2, float v3);

private:
	unsigned int GetUniformLocation(const std::string& name);
	unsigned int CreateShader(const std::string& vertexShader, const std::string& fragmentShader);
	unsigned int CompileShader(unsigned int type, const std::string& source);
	std::string ParseFile(const std::string& filePath);
};