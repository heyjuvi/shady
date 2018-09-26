using GL;

namespace Shady.Core
{
	public class CompileResources
	{

		public signal void compilation_finished();
		public signal void pass_compilation_terminated(int pass_index, ShaderError? e);

		public GLuint vertex_shader;
		public GLuint fragment_shader;

		public Mutex mutex;
		public Cond cond;

		public Gdk.Window window;

		public CompileResources()
		{
	 	}

	}
}
