using GL;
using Gtk;
using Gdk;

namespace Shady
{
	public errordomain ShaderError
	{
		COMPILATION
	}

	public class ShaderArea : DrawingArea
	{
		private const int num_textures = 4;
		private GLuint[] tex_ids = new GLuint[num_textures];
		private string[] channel_string = {"iChannel0", "iChannel1", "iChannel2", "iChannel3"};

		private GLuint program;
		private GLuint program2;
		private GLuint fragment_shader;
		private GLuint[] vao = { 1337 };
		private GLint date_loc;
		private GLint time_loc;
		private GLint delta_loc;
		private GLint fps_loc;
		private GLint frame_loc;
		private GLint res_loc;
		private GLint mouse_loc;
		private GLint[] channel_loc = new GLint[num_textures];
		private GLint samplerate_loc;
		private int64 start_time;
		private int64 curr_time;
		private int64 pause_time;
		private int64 delta_time;

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

		public double time_slider = 0.0;
		private const double time_slider_factor = 2.0;

		private bool program_switch = true;

		private GlContext gl_context;

		private DateTime curr_date;

		private Shader curr_shader;

		public ShaderArea(Shader default_shader)
		{
			initialized = false;

			curr_shader = default_shader;

			string fragment_source="";

			for(int i=0; i<curr_shader.renderpasses.length;i++)
			{
				if(curr_shader.renderpasses.index(i).type == Shader.RenderpassType.IMAGE)
				{
					fragment_source = curr_shader.renderpasses.index(i).code;
				}
			}

			if(fragment_source.length == 0){
				print("No image buffer found!\n");
			}


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

				glGenTextures(num_textures, tex_ids);

				for(int i=0;i<num_textures;i++){
					glBindTexture( GL_TEXTURE_2D, tex_ids[0] );

					int tex_height = 512, tex_width = 512;
					uchar[] tex_buffer = new uchar[512*512*4*4];

					for(int j=0;j<512*512*4*4;j++)
					{
						if(j%2 == 0)
						{
							tex_buffer[i]=255;
						}
					}

					glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, tex_width, tex_height, 0, GL_RGBA, GL_FLOAT, (GLvoid[])tex_buffer);


					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

					/*
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
					glGenerateMipmap(GL_TEXTURE_2D);
					*/

					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

					/*
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
					*/

				}

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

							if(!render_thread1_running)
							{
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

							if(!render_thread2_running)
							{
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

				add_events( EventMask.BUTTON_PRESS_MASK | EventMask.BUTTON_RELEASE_MASK | EventMask.POINTER_MOTION_MASK );
			});

			button_press_event.connect((widget, event) =>
			{
				if (event.button == BUTTON_PRIMARY)
				{
					button_pressed = true;
					button_pressed_x = event.x;
					button_pressed_y = height - event.y - 1;
				}

				return false;
			});

			button_release_event.connect((widget, event) =>
			{
				if (event.button == BUTTON_PRIMARY)
				{
					button_pressed = false;
					button_released_x = event.x;
					button_released_y = height - event.y - 1;
				}

				return false;
			});

			motion_notify_event.connect((widget, event) =>
			{
				mouse_x = event.x;
				mouse_y = height - event.y - 1;

				return false;
			});

			draw.connect((cairo_context) =>
			{
				if(buffer_mutex.trylock())
				{
					while(!buffer_rendered)
					{
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

					while(!old_buffer_rendered)
					{
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

				if(!prog_switch)
				{
					glUseProgram(program);
				}
				else
				{
					glUseProgram(program2);
				}

				delta_time = -curr_time;
				curr_time = get_monotonic_time();
				delta_time += curr_time;

				float delta;

				if (!paused)
				{
					time = (curr_time - start_time) / 1000000.0f;
					delta = delta_time / 1000000.0f;
				}
				else
				{
					time = (pause_time - start_time) / 1000000.0f;
					pause_time += (int)(time_slider * time_slider_factor * delta_time);
					delta = 0.0f;
				}

				//stdout.printf("%f\n",time);

				curr_date =  new DateTime.now_local();

				float year, month, day;
				curr_date.get_ymd(out year, out month, out day);

				float seconds = (float)((curr_date.get_hour()*60+curr_date.get_minute())*60)+(float)curr_date.get_seconds();

				//#TODO: synchronize locations with compiling

				glUniform4f(date_loc, year, month, day, seconds);
				glUniform1f(time_loc, (float)time);
				glUniform1f(delta_loc, (float)delta);
				//#TODO: implement proper frame counter
				glUniform1i(frame_loc, (int)(time*60));
				glUniform1f(fps_loc, (float)fps);
				glUniform3f(res_loc, width, height, 0);
				glUniform1f(samplerate_loc, 44100.0f);

				for(int i=0;i<num_textures;i++)
				{
					if(channel_loc[i] > 0)
					{
						glActiveTexture(GL_TEXTURE0 + i);
						glBindTexture(GL_TEXTURE_2D, tex_ids[i]);
						glUniform1i(channel_loc[i], (GLint)i);
					}
				}

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

				if(!prog_switch)
				{
					glUseProgram(program);
				}
				else
				{
					glUseProgram(program2);
				}

				glUniform4f(date_loc, 0.0f, 0.0f, 0.0f, 0.0f);
				glUniform1f(time_loc, 0.0f);
				glUniform1f(delta_loc, 0.0f);
				glUniform1i(frame_loc, 0);
				glUniform1f(fps_loc, 0.0f);
				glUniform3f(res_loc, width, height, 0);
				glUniform1f(samplerate_loc, 0.0f);

				glUniform4f(mouse_loc, 0.0f, 0.0f, 0.0f, 0.0f);

				glBindVertexArray(vao[0]);

				glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

				glFlush();
				glFinish();

				uchar[] dummy_buffer = new uchar[width*height*4];
				glReadPixels(0,0,width,height,GL_BGRA,GL_UNSIGNED_BYTE, (GLvoid[])dummy_buffer);
			}
		}

		public void compile(Shader new_shader) throws ShaderError
		{
			curr_shader = new_shader;

			new Thread<int>.try("compile_thread", () =>
			{

				if(compile_mutex.trylock())
				{
					string shader_source="";

					for(int i=0; i<curr_shader.renderpasses.length;i++)
					{
						if(curr_shader.renderpasses.index(i).type == Shader.RenderpassType.IMAGE)
						{
							shader_source = curr_shader.renderpasses.index(i).code;
						}
					}

					if(shader_source.length == 0)
					{
						print("No image buffer found!\n");
					}

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

			if(program_switch)
			{
				prog_mutex1.lock();
				glLinkProgram(program);
				date_loc = glGetUniformLocation(program, "iDate");
				time_loc = glGetUniformLocation(program, "iGlobalTime");
				delta_loc = glGetUniformLocation(program, "iTimeDelta");
				frame_loc = glGetUniformLocation(program, "iFrame");
				fps_loc = glGetUniformLocation(program, "iFrameRate");
				res_loc = glGetUniformLocation(program, "iResolution");
				samplerate_loc = glGetUniformLocation(program, "iSampleRate");
				mouse_loc = glGetUniformLocation(program, "iMouse");

				for(int i=0;i<num_textures;i++)
				{
					channel_loc[i] = glGetUniformLocation(program, channel_string[i]);
				}
			}
			else
			{
				prog_mutex2.lock();
				glLinkProgram(program2);
				date_loc = glGetUniformLocation(program2, "iDate");
				time_loc = glGetUniformLocation(program2, "iGlobalTime");
				delta_loc = glGetUniformLocation(program2, "iTimeDelta");
				frame_loc = glGetUniformLocation(program2, "iFrame");
				fps_loc = glGetUniformLocation(program2, "iFrameRate");
				res_loc = glGetUniformLocation(program2, "iResolution");
				samplerate_loc = glGetUniformLocation(program2, "iSampleRate");
				mouse_loc = glGetUniformLocation(program2, "iMouse");

				for(int i=0;i<num_textures;i++)
				{
					channel_loc[i] = glGetUniformLocation(program2, channel_string[i]);
				}
			}

			//prevent averaging in of old shader
			fps = 0;

			program_switch = !program_switch;

			if(!program_switch)
			{
				prog_mutex1.unlock();
			}
			else
			{
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
			pause_time = curr_time;
		}

	}
}
