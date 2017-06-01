using GL;
using Gtk;

namespace Shady
{
	public errordomain ShaderError
	{
		COMPILATION
	}

	public class ShaderArea : DrawingArea
	{
		private GLuint program;
		private GLuint program2;
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

		private uchar[] buffer;
		private uchar[] old_buffer;
		private Mutex buffer_mutex = Mutex();
		private Mutex old_buffer_mutex = Mutex();
		private Mutex size_mutex = Mutex();

		private Cond draw_cond = Cond();
		private Cond render_cond = Cond();

		private bool buffer_drawn = false;
		private bool buffer_rendered = false;
		private bool old_buffer_rendered = false;

		private int width = 0;
		private int height = 0;

		private Mutex compile_mutex = Mutex();

		public bool paused { get; set; default = false; }
		public double fps { get; private set; }
		public double time { get; private set; }

		private bool program_switch = false;

		//private static GlContext gl_context = new GlContext();
		//private GlContext gl_context = new GlContext();
		private GlContext gl_context;

		public ShaderArea(string? fragment_source = null)
		{
			initialized = false;
			print("new shader area\n");

			realize.connect(() =>
			{

				gl_context = new GlContext();
				
				fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);

				program = glCreateProgram();
				program2 = glCreateProgram();

				glAttachShader(program, gl_context.vertex_shader);
				glAttachShader(program, fragment_shader);

				glAttachShader(program2, gl_context.vertex_shader);
				glAttachShader(program2, fragment_shader);

				compile_blocking(fragment_source);
				compile_blocking(fragment_source);

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
				GLuint attrib2 = glGetAttribLocation(program2, "v");

				glEnableVertexAttribArray(attrib);
				glVertexAttribPointer(attrib, 2, GL_FLOAT, (GLboolean) GL_FALSE, 0, null);

				glEnableVertexAttribArray(attrib2);
				glVertexAttribPointer(attrib2, 2, GL_FLOAT, (GLboolean) GL_FALSE, 0, null);

				glBindBuffer(GL_ARRAY_BUFFER, 0);
				glBindVertexArray(0);

				glDeleteBuffers(1, vbo);

				start_time = get_monotonic_time();

				initialized = true;

				gl_context.unbind_context();

				new Thread<int>.try("render_thread", () =>
				{
					gl_context.main_context();

					while(true){
						render_gl(program_switch);
						Idle.add(() => {
							queue_draw();
							return false;
						}, Priority.HIGH);
					}
				});

				print("realized\n");

			});

			draw.connect((cairo_context) =>
			{
				Cairo.ImageSurface image;

				if(buffer_mutex.trylock())
				{

					while(!buffer_rendered){
						render_cond.wait(buffer_mutex);
					}

					image = new Cairo.ImageSurface.for_data(buffer, Cairo.Format.RGB24, width, height, Cairo.Format.RGB24.stride_for_width(width));
					buffer_drawn = true;
					draw_cond.signal();
					buffer_mutex.unlock();
				}
				else
				{
					old_buffer_mutex.lock();

					while(!old_buffer_rendered){
						render_cond.wait(old_buffer_mutex);
					}

					image = new Cairo.ImageSurface.for_data(old_buffer, Cairo.Format.RGB24, width, height, Cairo.Format.RGB24.stride_for_width(width));
					old_buffer_mutex.unlock();

				}

				cairo_context.translate(width*0, height);
				cairo_context.scale(1,-1);

				cairo_context.set_source_surface(image, 0, 0);
				cairo_context.paint();

				queue_draw();


				return true;

			});

			size_allocate.connect((allocation) =>
			{
				print("size allocated\n");
				size_mutex.lock();
				buffer_mutex.lock();
				width=allocation.width;
				height=allocation.height;

				buffer=new uchar[width*height*4];
				buffer_rendered = false;
				old_buffer_rendered = false;
				buffer_mutex.unlock();
				size_mutex.unlock();
				buffer_drawn = true;
				draw_cond.signal();
			});

			show.connect(() =>
			{
				print("shader area shown\n");
			});

		}

		public void render_gl(bool prog_switch)
		{
			if (initialized)
			{
				size_mutex.lock();

				while(!buffer_drawn)
				{
					draw_cond.wait(size_mutex);
				}

				glViewport(0, 0, width, height);

				if(!prog_switch){
					glUseProgram(program);
				}
				else{
					glUseProgram(program2);
				}

				if (!paused)
				{
					curr_time = get_monotonic_time();
					time = (curr_time - start_time) / 1000000.0f;
				}
				else
				{
					time = (pause_time - start_time) / 1000000.0f;
				}

				//stdout.printf("%f\n",time);

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

				// compute moving average
				if (fps != 0)
				{
					fps = (0.95 * fps + 0.05 * (1000000.0f / (time_after - time_before)));
				}
				else
				{
					fps = 1000000.0f / (time_after - time_before);
				}

				old_buffer_mutex.lock();
				old_buffer_rendered=buffer_rendered;
				old_buffer=buffer;
				old_buffer_mutex.unlock();
				buffer_mutex.lock();
				glReadPixels(0,0,width,height,GL_BGRA,GL_UNSIGNED_BYTE, (GLvoid[])buffer);

				buffer_rendered = true;
				render_cond.signal();

				buffer_mutex.unlock();

				size_mutex.unlock();
			}
		}

		public void compile(string shader_source) throws ShaderError
		{
			new Thread<int>.try("compile_thread", () =>
			{
				if(compile_mutex.trylock())
				{
					gl_context.thread_context();
					compile_blocking(shader_source);

					gl_context.free_context();
					compile_mutex.unlock();
				}

				return 0;
			});
		}

		public void compile_blocking(string shader_source) throws ShaderError
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
				stdout.printf("compile error\n");
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

				return;
			}

			if(program_switch){
				glLinkProgram(program);
			}
			else{
				glLinkProgram(program2);
			}

			int[] tmp=new int[1];

			if(program_switch){
				glGetProgramiv(program,GL_LINK_STATUS,tmp);
			}
			else{
				glGetProgramiv(program2,GL_LINK_STATUS,tmp);
			}

			if(program_switch){
				time_loc = glGetUniformLocation(program, "iGlobalTime");
			}
			else{
				time_loc = glGetUniformLocation(program2, "iGlobalTime");
			}
			if(program_switch){
				res_loc = glGetUniformLocation(program, "iResolution");
			}
			else{
				res_loc = glGetUniformLocation(program2, "iResolution");
			}
			if(program_switch){
				mouse_loc = glGetUniformLocation(program, "iMouse");
			}
			else{
				mouse_loc = glGetUniformLocation(program2, "iMouse");
			}

			//prevent averaging in of old shader
			fps=0;

			program_switch=!program_switch;
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
			button_pressed = false;
			button_released_x = x;
			button_released_y = get_allocated_height() - y - 1;
		}
	}
}
