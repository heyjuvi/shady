#ifndef _GLSLANG_BINDINGS_H
#define _GLSLANG_BINDINGS_H

extern "C"
{
	int glslang_initialize();
	void glslang_finalize();
	int glslang_validate(const char *, int, char **, char **);
}

#endif
