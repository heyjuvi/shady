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

		private double mouse_x = 0;
		private double mouse_y = 0;

		private uchar[] buffer;
		private uchar[] old_buffer;
		private Mutex buffer_mutex = Mutex();
		private Mutex old_buffer_mutex = Mutex();
		private Mutex size_mutex = Mutex();

		private Mutex render_switch_mutex1 = Mutex();
		private Mutex render_switch_mutex2 = Mutex();
		private Cond render_switch_cond = Cond();

		private Cond draw_cond = Cond();
		private Cond render_cond = Cond();

		private bool buffer_drawn = false;
		private bool buffer_rendered = false;
		private bool old_buffer_rendered = false;

		private int width = 0;
		private int height = 0;
		private int stride = 0;

		private Thread<int> render_thread1;
		private Thread<int> render_thread2;
		private bool render_thread1_running = true;
		private bool render_thread2_running = true;

		private bool render_switch = true;

		private Mutex compile_mutex = Mutex();

		private Mutex prog_mutex1 = Mutex();
		private Mutex prog_mutex2 = Mutex();

		public bool paused { get; set; default = false; }
		public double fps { get; private set; }
		public double time { get; private set; }

		private bool program_switch = true;

		//private static GlContext gl_context = new GlContext();
		//private GlContext gl_context = new GlContext();
		private GlContext gl_context;

		public ShaderArea(string? fragment_source = null)
		{
			initialized = false;

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

				gl_context.render_context1();

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

				gl_context.render_context2();

				glGenVertexArrays(1, vao);
				glBindVertexArray(vao[0]);

				glGenBuffers(1, vbo);

				glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
				glBufferData(GL_ARRAY_BUFFER, vertices.length * sizeof (GLfloat), (GLvoid[]) vertices, GL_STATIC_DRAW);

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

				render_thread1 = new Thread<int>.try("render_thread1", () =>
				{
					gl_context.render_context1();

					while(render_thread1_running)
					{

						Idle.add(() =>
						{
							queue_draw();
							return false;

						}, Priority.HIGH);

						render_switch_mutex1.lock();

						while(!render_switch && render_thread1_running)
						{
							render_switch_cond.wait(render_switch_mutex1);

							if(!render_thread1_running){
								continue;
							}

							prog_mutex2.lock();
							dummy_render_gl(true);
							prog_mutex2.unlock();
							render_switch = !render_switch;
						}
						
						render_switch_mutex1.unlock();

						prog_mutex2.lock();
						render_gl(true);
						prog_mutex2.unlock();
					}
					return 0;
				});

				render_thread2 = new Thread<int>.try("render_thread2", () =>
				{
					gl_context.render_context2();

					while(render_thread2_running)
					{
						Idle.add(() =>
						{
							queue_draw();
							return false;

						}, Priority.HIGH);
						
						render_switch_mutex2.lock();

						while(render_switch && render_thread2_running)
						{
							render_switch_cond.wait(render_switch_mutex2);

							if(!render_thread2_running){
								continue;
							}

							prog_mutex1.lock();
							dummy_render_gl(false);
							prog_mutex1.unlock();
							render_switch = !render_switch;
						}
						
						render_switch_mutex2.unlock();

						prog_mutex1.lock();
						render_gl(false);
						prog_mutex1.unlock();
					}
					return 0;
				});
			});

			draw.connect((cairo_context) =>
			{
				if(buffer_mutex.trylock())
				{
					while(!buffer_rendered){
						render_cond.wait(buffer_mutex);
					}

					Cairo.ImageSurface image = new Cairo.ImageSurface.for_data(buffer, Cairo.Format.RGB24, width, height, stride);

					cairo_context.translate(width*0, height);
					cairo_context.scale(1,-1);

					cairo_context.set_source_surface(image, 0, 0);

					cairo_context.paint();

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

					Cairo.ImageSurface image = new Cairo.ImageSurface.for_data(old_buffer, Cairo.Format.RGB24, width, height, stride);
					cairo_context.translate(width*0, height);
					cairo_context.scale(1,-1);

					cairo_context.set_source_surface(image, 0, 0);

					cairo_context.paint();

					old_buffer_mutex.unlock();
				}


				queue_draw();

				return true;

			});

			size_allocate.connect((allocation) =>
			{
				size_mutex.lock();
				buffer_mutex.lock();
				old_buffer_mutex.lock();
				width = allocation.width;
				height = allocation.height;
				stride = Cairo.Format.RGB24.stride_for_width(width);

				buffer = new uchar[stride*height];
				buffer_rendered = false;
				old_buffer_rendered = false;
				old_buffer_mutex.unlock();
				buffer_mutex.unlock();
				size_mutex.unlock();
				buffer_drawn = true;
				draw_cond.signal();
			});

			unrealize.connect(()=>
			{
				render_thread1_running = false;
				render_thread2_running = false;

				render_switch_cond.signal();

				render_thread1.join();
				render_thread2.join();
				compile_mutex.lock();
				compile_mutex.unlock();
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


				//Gdk.Device mouse_device = get_display().get_default_seat().get_pointer();
				//get_window().get_device_position_double(mouse_device, out mouse_x, out mouse_y, null);


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

				//stdout.printf("before draw in thread:%d\n",(int)prog_switch);
				glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
				//stdout.printf("after draw in thread:%d\n",(int)prog_switch);

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
				old_buffer_rendered = buffer_rendered;
				old_buffer = buffer;
				old_buffer_mutex.unlock();
				buffer_mutex.lock();
				glReadPixels(0,0,width,height,GL_BGRA,GL_UNSIGNED_BYTE, (GLvoid[])buffer);

				buffer_rendered = true;
				render_cond.signal();

				buffer_mutex.unlock();

				size_mutex.unlock();
			}
		}

		public void dummy_render_gl(bool prog_switch)
		{
			if (initialized)
			{
				glViewport(0, 0, width, height);

				if(!prog_switch){
					glUseProgram(program);
				}
				else{
					glUseProgram(program2);
				}

				glUniform1f(time_loc, 0.0f);
				glUniform3f(res_loc, width, height, 0);

				glUniform4f(mouse_loc, 0.0f, 0.0f, 0.0f, 0.0f);

				glBindVertexArray(vao[0]);

				glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

				glFlush();
				glFinish();

				uchar[] dummy_buffer = new uchar[width*height*4];
				glReadPixels(0,0,width,height,GL_BGRA,GL_UNSIGNED_BYTE, (GLvoid[])dummy_buffer);
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

					//render_switch = !render_switch;
					render_switch_cond.signal();
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
				prog_mutex1.lock();
			}
			else{
				prog_mutex2.lock();
			}

			if(program_switch){
				glLinkProgram(program);
			}
			else{
				glLinkProgram(program2);
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
			fps = 0;

			program_switch = !program_switch;

			if(!program_switch){
				prog_mutex1.unlock();
			}
			else{
				prog_mutex2.unlock();
			}
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
			button_pressed_y = height - y - 1;
		}

		public void button_release(double x, double y)
		{
			button_pressed = false;
			button_released_x = x;
			button_released_y = height - y - 1;
		}

		public void mouse_move(double x, double y)
		{
			mouse_x = x;
			mouse_y = height - y - 1;
		}
	}
}
