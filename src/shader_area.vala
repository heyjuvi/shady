using GL;
using Gtk;

namespace Shady
{
	public errordomain ShaderError
	{
		COMPILATION
	}

	public class ShaderArea : GLArea
	{
		private GLuint program;
		private GLuint fragment_shader;
		private GLuint[] vao = { 1337 };
		private GLint time_loc;
		private GLint res_loc;
		private GLint mouse_loc;
		private int64 start_time;
		private int64 curr_time;
		private int64 pause_time;

		private bool initialized;

		private bool button_pressed;
		private double button_pressed_x;
		private double button_pressed_y;
		private double button_released_x;
		private double button_released_y;

		public bool paused { get; set; default = false; }
		public double fps;
		public double time;

		public ShaderArea(string? fragment_source = null)
		{
			this.initialized = false;

			this.realize.connect(() =>
			{
				this.make_current();

				if (this.get_error() != null)
				{
					return;
				}

				string vertex_source = (string) (resources_lookup_data("/org/hasi/shady/data/shader/vertex.glsl", 0).get_data());
				string[] vertex_source_array = { vertex_source, null };

				GLuint vertex_shader = glCreateShader(GL_VERTEX_SHADER);
				glShaderSource(vertex_shader, 1, vertex_source_array, null);
				glCompileShader(vertex_shader);

				fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);

				program = glCreateProgram();

				glAttachShader(program, vertex_shader);
				glAttachShader(program, fragment_shader);

				compile(fragment_source);

				glGenVertexArrays(1, vao);
				glBindVertexArray(vao[0]);

				GLuint[] vbo = { 1337 };
				glGenBuffers(1, vbo);

				GLfloat[] vertices = {  1,  1,
					                   -1,  1,
					                   -1, -1,
					                    1, -1 };

				glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
				glBufferData(GL_ARRAY_BUFFER, vertices.length * sizeof (GLfloat), (GLvoid[]) vertices, GL_STATIC_DRAW);

				GLuint attrib = glGetAttribLocation(program, "v");

				glEnableVertexAttribArray(attrib);
				glVertexAttribPointer(attrib, 2, GL_FLOAT, (GLboolean) GL_FALSE, 0, null);

				glBindBuffer(GL_ARRAY_BUFFER, 0);
				glBindVertexArray(0);

				glDeleteBuffers(1, vbo);

				start_time = get_monotonic_time();

				initialized = true;
			});

			//this.size_allocate.connect(render_gl);
			this.render.connect(on_render);
		}

		private bool on_render()
		{
			this.render_gl();
			this.queue_draw();

			return true;
		}

		public void render_gl()
		{
			if (this.initialized)
			{
				glClearColor(0, 0, 0, 1);
				glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

				int width = this.get_allocated_width();
				int height = this.get_allocated_height();

				glViewport(0, 0, width, height);

				glUseProgram(program);

				if (!paused)
				{
					curr_time = get_monotonic_time();
					time = (curr_time - start_time) / 1000000.0f;
				}
				else
				{
					time = (pause_time - start_time) / 1000000.0f;
				}

				glUniform1f(time_loc, (float)time);
				glUniform3f(res_loc, width, height, 0);

				Gdk.Device mouse_device = get_display().get_default_seat().get_pointer();

				double mouse_x, mouse_y;

				get_window().get_device_position_double(mouse_device, out mouse_x, out mouse_y, null);

				mouse_y = height - mouse_y - 1;

				if (button_pressed)
				{
					glUniform4f(mouse_loc, (float) mouse_x, (float) mouse_y, (float) button_pressed_x, (float) button_pressed_y);
				}
				else
				{
					glUniform4f(mouse_loc, (float) button_released_x, (float) button_released_y, -(float) button_pressed_x, -(float) button_pressed_y);
				}

				glBindVertexArray(vao[0]);

				glFinish();

				int64 time_before = get_monotonic_time();

				glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

				glFlush();
				glFinish();

				int64 time_after = get_monotonic_time();

				//compute moving average
				if(fps!=0){
					fps=(0.95*fps + 0.05*(1000000.0f / (time_after - time_before)));
				}
				else{
					fps=1000000.0f / (time_after - time_before);
				}
			}
		}

		public void compile(string shader_source) throws ShaderError
		{

			string shader_prefix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/prefix.glsl", 0).get_data());
			string shader_suffix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/suffix.glsl", 0).get_data());

			string full_shader_source = shader_prefix + shader_source + shader_suffix;

			string[] source_array = { full_shader_source, null };

			glShaderSource(fragment_shader, 1, source_array, null);
			glCompileShader(fragment_shader);

			GLint success[] = {0};
			glGetShaderiv(fragment_shader, GL_COMPILE_STATUS, success);

			if (success[0] == GL_FALSE)
			{
				GLint log_size[] = {0};
				glGetShaderiv(fragment_shader, GL_INFO_LOG_LENGTH, log_size);
				GLubyte[] log = new GLubyte[log_size[0]];
				glGetShaderInfoLog(fragment_shader, log_size[0], log_size, log);

				if (log.length > 0)
				{
					//throw new ShaderError.COMPILATION((string) log);
					foreach (GLubyte c in log)
					{
						stdout.printf("%c", c);
					}
				}
				else
				{
					throw new ShaderError.COMPILATION("Something went wrong.");
				}
			}

			glLinkProgram(program);

			time_loc = glGetUniformLocation(program, "iGlobalTime");
			res_loc = glGetUniformLocation(program, "iResolution");
			mouse_loc = glGetUniformLocation(program, "iMouse");

			//prevent averaging in of old shader
			fps=0;
		}

		public void pause(bool pause_status)
		{
			paused = pause_status;

			if (pause_status == true)
			{
				pause_time = get_monotonic_time();
			}
			else
			{
				start_time += get_monotonic_time() - pause_time;
			}
		}

		public void reset_time()
		{
			start_time = curr_time;
		}

		public void button_press(double x, double y)
		{
			button_pressed = true;
			button_pressed_x = x;
			button_pressed_y = get_allocated_height() - y - 1;
		}

		public void button_release(double x, double y)
		{
			button_pressed=false;
			button_released_x = x;
			button_released_y = get_allocated_height() - y - 1;
		}
	}
}
