#ifndef _GLSLANG_H
#define _GLSLANG_H

int glslang_initialize();
void glslang_finalize();
int glslang_validate(const char *, int, char **, char **);

#endif
