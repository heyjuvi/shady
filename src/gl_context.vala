using GL;
using EGL;

namespace Shady
{
	public class GlContext
	{
		private EGLDisplay egl_display;
		private EGLConfig[] egl_pbuffer_conf = new EGLConfig[1];
		private EGLSurface egl_pbuffer_surface1;
		private EGLSurface egl_pbuffer_surface2;
		private EGLContext egl_render_context1;
		private EGLContext egl_render_context2;

		private EGLint num_configs;

		public GLuint vertex_shader;

		private const EGLint pbuffer_attribs[] =
		{
			EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
			EGL_RED_SIZE, 8,
			EGL_GREEN_SIZE, 8,
			EGL_BLUE_SIZE, 8,
			EGL_ALPHA_SIZE, 0,
			EGL_DEPTH_SIZE, 0,
			EGL_STENCIL_SIZE, 0,
			EGL_NONE
		};

		private const EGLint pbuffer_surface_attribs[] =
		{
			EGL_WIDTH, 133742,
			EGL_HEIGHT, 133742,
			//EGL_TEXTURE_FORMAT, EGL_TEXTURE_RGB,
			//EGL_TEXTURE_TARGET, EGL_TEXTURE_2D,
			EGL_LARGEST_PBUFFER, EGL_TRUE,
			EGL_NONE
		};

		private const EGLint contextAttr[] =
		{
			//EGL_CONTEXT_CLIENT_VERSION, 2,//opengl es version
			EGL_CONTEXT_MAJOR_VERSION, 3,
			EGL_CONTEXT_MINOR_VERSION, 3,
			EGL_CONTEXT_OPENGL_PROFILE_MASK, EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT,
			EGL_NONE
		};

		public GlContext()
		{
			eglBindAPI(EGL_OPENGL_API);
			//eglBindAPI(EGL_OPENGL_ES_API);

			egl_display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
			eglInitialize(egl_display, null, null);

			eglChooseConfig(egl_display, pbuffer_attribs, egl_pbuffer_conf, 1, out num_configs);
			egl_render_context1 = eglCreateContext(egl_display, egl_pbuffer_conf[0], (EGLContext)EGL_NO_CONTEXT, contextAttr);
			egl_render_context2 = eglCreateContext(egl_display, egl_pbuffer_conf[0], egl_render_context1, contextAttr);

			egl_pbuffer_surface1 = eglCreatePbufferSurface(egl_display, egl_pbuffer_conf[0],pbuffer_surface_attribs);
			egl_pbuffer_surface2 = eglCreatePbufferSurface(egl_display, egl_pbuffer_conf[0],pbuffer_surface_attribs);

			eglMakeCurrent(egl_display, egl_pbuffer_surface2, egl_pbuffer_surface2, egl_render_context2);
			glReadBuffer(GL_FRONT);
			glDrawBuffer(GL_FRONT);


			eglMakeCurrent(egl_display, egl_pbuffer_surface1, egl_pbuffer_surface1, egl_render_context1);

			glReadBuffer(GL_FRONT);
			glDrawBuffer(GL_FRONT);

			string vertex_source = (string) (resources_lookup_data("/org/hasi/shady/data/shader/vertex.glsl", 0).get_data());
			string[] vertex_source_array = { vertex_source, null };

			vertex_shader = glCreateShader(GL_VERTEX_SHADER);
			glShaderSource(vertex_shader, 1, vertex_source_array, null);
			glCompileShader(vertex_shader);
		}

		public void render_context1()
		{
				eglMakeCurrent(egl_display, egl_pbuffer_surface1, egl_pbuffer_surface1, egl_render_context1);
		}

		public void render_context2()
		{
				eglMakeCurrent(egl_display, egl_pbuffer_surface2, egl_pbuffer_surface2, egl_render_context2);
		}

		public void unbind_context()
		{
				eglMakeCurrent(egl_display, (EGLSurface) EGL_NO_SURFACE, (EGLSurface) EGL_NO_SURFACE, (EGLContext) EGL_NO_CONTEXT);
		}

		public void thread_context()
		{
				eglBindAPI(EGL_OPENGL_API);
				//eglBindAPI(EGL_OPENGL_ES_API);

				EGLContext curr_context = eglCreateContext(egl_display, egl_pbuffer_conf[0], egl_render_context1, contextAttr);
				eglMakeCurrent(egl_display, (EGLSurface) EGL_NO_SURFACE, (EGLSurface) EGL_NO_SURFACE, curr_context);
		}

		public void free_context()
		{
				EGLContext curr_context = eglGetCurrentContext();
				eglMakeCurrent(egl_display, (EGLSurface) EGL_NO_SURFACE, (EGLSurface) EGL_NO_SURFACE, (EGLContext) EGL_NO_CONTEXT);
				eglDestroyContext(egl_display, curr_context);
		}
	}
}
