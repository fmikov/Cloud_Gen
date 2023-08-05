#pragma once

#include "Renderer.h"

class Texture {
private:
	unsigned int m_RendererID;
	std::string m_Filepath;
	unsigned char* m_LocalBuffer;
	int m_Width, m_Height, m_BPP; //bits-per-pixel
public:
	Texture(const std::string& filepath);
	~Texture();

	void Bind(unsigned int slot = 0) const; //optional parameter, specify texture slot
	void Unbind();

	int GetWidth() const { return m_Width; }
	int GetHeight() const { return m_Height; }
};