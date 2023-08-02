#pragma once
#include <vector>
#include <GL/glew.h>
#include "Renderer.h"


struct VertexBufferElement {
	unsigned int type;
	unsigned int count;
	bool normalized;

	static unsigned int SizeOfType(unsigned int type) {
		switch (type) {
		case GL_FLOAT:			return 4;
		case GL_UNSIGNED_INT:	return 4;
		case GL_UNSIGNED_BYTE:	return 1;
		}
		//unsupported type
		ASSERT(false);
		return 0;
	}
};

class VertexBufferLayout {
private:
	std::vector<VertexBufferElement> m_Elements;
	unsigned int m_Stride;

public:
	VertexBufferLayout()
		: m_Stride(0) {}


	void Push(unsigned int type, unsigned int count)
	{
		m_Elements.push_back({ type, count, GL_FALSE });
		m_Stride += count * VertexBufferElement::SizeOfType(type);
	}

	const std::vector<VertexBufferElement> GetElements() const {
		return m_Elements;
	}
	unsigned int GetStride() const {
		return m_Stride;
	}

};
