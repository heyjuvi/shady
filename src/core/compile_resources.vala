using GL;

namespace Shady.Core
{
	public class CompileResources
	{

		public signal void compilation_started();
		public signal void compilation_finished();
		public signal void pass_compilation_terminated(int pass_index, ShaderError? e);

		public GLuint vertex_shader;
		public GLuint fragment_shader;

		public GLuint vbo;

		public Mutex mutex = Mutex();

		public Gdk.Window window;

		public int width;
		public int height;

		public CompileResources()
		{
	 	}

	}
}
