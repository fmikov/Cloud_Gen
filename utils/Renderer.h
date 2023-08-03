#pragma once

#include <GL/glew.h>

#include "IndexBuffer.h"
#include "Shader.h"
#include "VertexArray.h"

class Renderer {
//private:
public:
	void Draw(const VertexArray& va, const IndexBuffer& ib, const Shader& shader);
	void Clear() const;
};