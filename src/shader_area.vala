using GL;
using Gtk;
using Gdk;

namespace Shady
{
	public errordomain ShaderError
	{
		COMPILATION
	}

	public class ShaderArea : EventBox
	{
		public signal void compilation_finished();

		public delegate void ShaderErrorHandler(ShaderError e);

		struct BufferProperties {
			public GLuint program;

			public GLuint[] tex_ids;

			public int[] tex_widths;
			public int[] tex_heights;

			public double[] tex_times;

			public GLint date_loc;
			public GLint global_time_loc;
			public GLint time_loc;
			public GLint channel_time_loc;
			public GLint delta_loc;
			public GLint fps_loc;
			public GLint frame_loc;
			public GLint res_loc;
			public GLint channel_res_loc;
			public GLint mouse_loc;
			public GLint samplerate_loc;
			public GLint[] channel_loc;
		}

		/* Properties */
		private bool _paused = false;
		public bool paused
		{
			get { return _paused; }
			set
			{
				if (value == true)
				{
					_pause_time = get_monotonic_time();
				}
				else
				{
					_start_time += get_monotonic_time() - _pause_time;
				}

				_paused = value;
			}
		}

		public double fps { get; private set; }
		public double time { get; private set; }
		public double time_slider { get; set; default = 0.0; }

		/* Buffer properties structs*/
		private BufferProperties _image_prop1;
		private BufferProperties _image_prop2;

		private BufferProperties[] _buffer_props1;
		private BufferProperties[] _buffer_props2;

		/* Objects */
		private GlContext _gl_context;
		//private Shader _curr_shader;

		/* Constants */
		private const double _time_slider_factor = 2.0;
		private const int _num_textures = 4;

		/* OpenGL ids */
		private GLuint[] _tex_ids = new GLuint[_num_textures];
		private string[] _channel_string = {"iChannel0", "iChannel1", "iChannel2", "iChannel3"};

		private GLuint _program1;
		private GLuint _program2;
		private GLuint _fragment_shader;
		private GLuint[] _vao = { 1337 };

		private GLint _date_loc;
		private GLint _global_time_loc;
		private GLint _time_loc;
		private GLint _channel_time_loc;
		private GLint _delta_loc;
		private GLint _fps_loc;
		private GLint _frame_loc;
		private GLint _res_loc;
		private GLint _channel_res_loc;
		private GLint _mouse_loc;
		private GLint _samplerate_loc;
		private GLint[] _channel_loc = new GLint[_num_textures];

		/* Time variables */
		private DateTime _curr_date;

		private int64 _start_time;
		private int64 _curr_time;
		private int64 _pause_time;
		private int64 _delta_time;

		private float _year;
		private float _month;
		private float _day;
		private float _seconds;

		private float _delta;

		private float _samplerate = 44100.0f;

		/* Initialized */
		private bool _initialized = false;

		/* Mouse variables */
		private bool _button_pressed;
		private double _button_pressed_x;
		private double _button_pressed_y;
		private double _button_released_x;
		private double _button_released_y;

		private double _mouse_x = 0;
		private double _mouse_y = 0;

		/* Shader render buffer variables */

		private int _width = 0;
		private int _height = 0;
		private int _stride = 0;

		private uchar[] _buffer;
		private uchar[] _old_buffer;

		/* Threads and sync variables */
		private Mutex _buffer_mutex = Mutex();
		private Mutex _old_buffer_mutex = Mutex();
		private Mutex _size_mutex = Mutex();

		private bool _render_switch = true;
		private bool _program_switch = true;

		private Mutex _render_switch_mutex1 = Mutex();
		private Mutex _render_switch_mutex2 = Mutex();
		private Cond _render_switch_cond = Cond();

		private Cond _draw_cond = Cond();
		private Cond _render_cond = Cond();

		private bool _buffer_drawn = false;
		private bool _buffer_rendered = false;
		private bool _old_buffer_rendered = false;

		private Thread<int> _render_thread1;
		private Thread<int> _render_thread2;
		private bool _render_thread1_running = true;
		private bool _render_thread2_running = true;

		private Mutex _compile_mutex = Mutex();

		private Mutex _prog_mutex1 = Mutex();
		private Mutex _prog_mutex2 = Mutex();

		public ShaderArea(Shader default_shader)
		{

			//_curr_shader = default_shader;

			realize.connect(() =>
			{
				init_gl(default_shader);
			});

			button_press_event.connect((widget, event) =>
			{
				if (event.button == BUTTON_PRIMARY)
				{
					_button_pressed = true;
					_button_pressed_x = event.x;
					_button_pressed_y = _height - event.y - 1;
				}

				return false;
			});

			button_release_event.connect((widget, event) =>
			{
				if (event.button == BUTTON_PRIMARY)
				{
					_button_pressed = false;
					_button_released_x = event.x;
					_button_released_y = _height - event.y - 1;
				}

				return false;
			});

			motion_notify_event.connect((widget, event) =>
			{
				_mouse_x = event.x;
				_mouse_y = _height - event.y - 1;

				return false;
			});

			draw.connect((cairo_context) =>
			{
				if(_buffer_mutex.trylock())
				{
					while(!_buffer_rendered)
					{
						_render_cond.wait(_buffer_mutex);
					}

					Cairo.ImageSurface image = new Cairo.ImageSurface.for_data(_buffer, Cairo.Format.RGB24, _width, _height, _stride);

					cairo_context.translate(_width*0, _height);
					cairo_context.scale(1,-1);

					cairo_context.set_source_surface(image, 0, 0);

					cairo_context.paint();

					_buffer_drawn = true;
					_draw_cond.signal();
					_buffer_mutex.unlock();
				}
				else
				{
					_old_buffer_mutex.lock();

					while(!_old_buffer_rendered)
					{
						_render_cond.wait(_old_buffer_mutex);
					}

					Cairo.ImageSurface image = new Cairo.ImageSurface.for_data(_old_buffer, Cairo.Format.RGB24, _width, _height, _stride);
					cairo_context.translate(_width*0, _height);
					cairo_context.scale(1,-1);

					cairo_context.set_source_surface(image, 0, 0);

					cairo_context.paint();

					_old_buffer_mutex.unlock();
				}


				queue_draw();

				return true;

			});

			size_allocate.connect((allocation) =>
			{
				_size_mutex.lock();
				_buffer_mutex.lock();
				_old_buffer_mutex.lock();
				_width = allocation.width;
				_height = allocation.height;
				_stride = Cairo.Format.RGB24.stride_for_width(_width);

				_buffer = new uchar[_stride*_height];
				_buffer_rendered = false;
				_old_buffer_rendered = false;
				_old_buffer_mutex.unlock();
				_buffer_mutex.unlock();
				_size_mutex.unlock();
				_buffer_drawn = true;
				_draw_cond.signal();
			});

			unrealize.connect(()=>
			{
				_render_thread1_running = false;
				_render_thread2_running = false;

				_render_switch_cond.signal();

				_render_thread1.join();
				_render_thread2.join();
				_compile_mutex.lock();
				_compile_mutex.unlock();
			});
		}

		public void compile(Shader new_shader, ShaderErrorHandler? callback=null)
		{
			//_curr_shader = new_shader;

			new Thread<int>("compile_thread", () =>
			{

				if(_compile_mutex.trylock())
				{
					_gl_context.thread_context();

					try
					{
						compile_blocking(new_shader);
					}
					catch (ShaderError e)
					{
						callback(e);
					}

					_gl_context.free_context();
					_compile_mutex.unlock();

					//_render_switch = !_render_switch;
					_render_switch_cond.signal();
				}

				return 0;
			});
		}

		public void compile_blocking(Shader new_shader) throws ShaderError
		{
			string image_source="";
			Array<string> buffer_sources = new Array<string>();

			for(int i=0; i<new_shader.renderpasses.length;i++)
			{
				if(new_shader.renderpasses.index(i).type == Shader.RenderpassType.IMAGE)
				{
					stdout.printf("IMAGE, i:%d\n",i);
					image_source = new_shader.renderpasses.index(i).code;
				}
				else if(new_shader.renderpasses.index(i).type == Shader.RenderpassType.BUFFER)
				{
					stdout.printf("BUFFER, i:%d\n",i);
					buffer_sources.append_val(new_shader.renderpasses.index(i).code);
				}
			}

			if(image_source.length == 0)
			{
				print("No image _buffer found!\n");
			}

			string shader_prefix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/prefix.glsl", 0).get_data());
			string shader_suffix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/suffix.glsl", 0).get_data());

			string full_image_source = shader_prefix + image_source + shader_suffix;


			string[] source_array = { full_image_source, null };

			glShaderSource(_fragment_shader, 1, source_array, null);
			glCompileShader(_fragment_shader);

			GLint success[] = {0};
			glGetShaderiv(_fragment_shader, GL_COMPILE_STATUS, success);

			if (success[0] == GL_FALSE)
			{
				stdout.printf("compile error\n");
				GLint log_size[] = {0};
				glGetShaderiv(_fragment_shader, GL_INFO_LOG_LENGTH, log_size);
				GLubyte[] log = new GLubyte[log_size[0]];
				glGetShaderInfoLog(_fragment_shader, log_size[0], log_size, log);

				if (log.length > 0)
				{
					foreach (GLubyte c in log)
					{
						stdout.printf("%c", c);
					}

					throw new ShaderError.COMPILATION((string) log);
				}
				else
				{
					throw new ShaderError.COMPILATION("Something went substantially wrong...");
				}

				return;
			}

			GLuint program;

			if(_program_switch)
			{
				program = _program1;
				_prog_mutex1.lock();
			}
			else
			{
				program = _program2;
				_prog_mutex2.lock();
			}

			glLinkProgram(program);

			_res_loc = glGetUniformLocation(program, "iResolution");
			_global_time_loc = glGetUniformLocation(program, "iGlobalTime");
			_time_loc = glGetUniformLocation(program, "iTime");
			_delta_loc = glGetUniformLocation(program, "iTimeDelta");
			_frame_loc = glGetUniformLocation(program, "iFrame");
			_fps_loc = glGetUniformLocation(program, "iFrameRate");
			_channel_time_loc = glGetUniformLocation(program, "iChannelTime");
			_channel_res_loc = glGetUniformLocation(program, "iChannelResolution");
			_mouse_loc = glGetUniformLocation(program, "iMouse");

			for(int i=0;i<_num_textures;i++)
			{
				_channel_loc[i] = glGetUniformLocation(program, _channel_string[i]);
			}

			_date_loc = glGetUniformLocation(program, "iDate");
			_samplerate_loc = glGetUniformLocation(program, "iSampleRate");

			//prevent averaging in of old shader
			fps = 0;

			_program_switch = !_program_switch;

			if(!_program_switch)
			{
				_prog_mutex1.unlock();
			}
			else
			{
				_prog_mutex2.unlock();
			}

			compilation_finished();
		}

		public void reset_time()
		{
			_start_time = _curr_time;
			_pause_time = _curr_time;
		}

		private void partial_compile()
		{

		}

		private void render_thread_func(bool thread_switch, Mutex prog_mutex, Mutex render_switch_mutex, ref bool thread_running)
		{
			if(thread_switch)
			{
				_gl_context.render_context1();
			}
			else
			{
				_gl_context.render_context2();
			}

			while(thread_running)
			{

				Idle.add(() =>
				{
					queue_draw();
					return false;

				}, Priority.HIGH);

				render_switch_mutex.lock();

				while(((thread_switch && !_render_switch) || (!thread_switch && _render_switch)) && thread_running)
				{
					_render_switch_cond.wait(render_switch_mutex);

					if(!thread_running)
					{
						continue;
					}

					prog_mutex.lock();
					dummy_render_gl(thread_switch);
					prog_mutex.unlock();
					_render_switch = !_render_switch;
				}
				
				render_switch_mutex.unlock();

				prog_mutex.lock();
				if(thread_switch)
				{
					render_image(_program2);
				}
				else
				{
					render_image(_program1);
				}
				prog_mutex.unlock();
			}
		}

		private void init_gl(Shader default_shader)
		{
			_gl_context = new GlContext();
			
			_fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);

			_program1 = glCreateProgram();
			_program2 = glCreateProgram();

			glAttachShader(_program1, _gl_context.vertex_shader);
			glAttachShader(_program1, _fragment_shader);

			glAttachShader(_program2, _gl_context.vertex_shader);
			glAttachShader(_program2, _fragment_shader);

			compile_blocking(default_shader);
			compile_blocking(default_shader);

			_gl_context.render_context1();

			glGenVertexArrays(1, _vao);
			glBindVertexArray(_vao[0]);

			GLuint[] vbo = { 1337 };
			glGenBuffers(1, vbo);

			GLfloat[] vertices = {  1,  1,
								   -1,  1,
								   -1, -1,
									1, -1 };

			glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
			glBufferData(GL_ARRAY_BUFFER, vertices.length * sizeof (GLfloat), (GLvoid[]) vertices, GL_STATIC_DRAW);

			GLuint attrib = glGetAttribLocation(_program1, "v");
			GLuint attrib2 = glGetAttribLocation(_program2, "v");

			glEnableVertexAttribArray(attrib);
			glVertexAttribPointer(attrib, 2, GL_FLOAT, (GLboolean) GL_FALSE, 0, null);

			glEnableVertexAttribArray(attrib2);
			glVertexAttribPointer(attrib2, 2, GL_FLOAT, (GLboolean) GL_FALSE, 0, null);

			glBindBuffer(GL_ARRAY_BUFFER, 0);
			glBindVertexArray(0);

			glDeleteBuffers(1, vbo);

			_gl_context.render_context2();

			glGenVertexArrays(1, _vao);
			glBindVertexArray(_vao[0]);

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

			glGenTextures(_num_textures, _tex_ids);

			for(int i=0;i<_num_textures;i++){
				glBindTexture( GL_TEXTURE_2D, _tex_ids[i] );

				int tex__height = 512, tex__width = 512;
				uchar[] tex__buffer = new uchar[512*512*4*4];

				for(int j=0;j<512*512*4*4;j++)
				{
					if(j%2 == 0)
					{
						tex__buffer[i]=255;
					}
				}

				glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, tex__width, tex__height, 0, GL_RGBA, GL_FLOAT, (GLvoid[])tex__buffer);


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

			_start_time = get_monotonic_time();

			_initialized = true;

			_gl_context.unbind_context();

			_render_thread1 = new Thread<int>.try("_render_thread1", () =>
			{
				render_thread_func(true, _prog_mutex2, _render_switch_mutex1, ref _render_thread1_running);
				return 0;
			});

			_render_thread2 = new Thread<int>.try("_render_thread2", () =>
			{
				render_thread_func(false, _prog_mutex1, _render_switch_mutex2, ref _render_thread2_running);
				return 0;
			});

			add_events(EventMask.BUTTON_PRESS_MASK |
					   EventMask.BUTTON_RELEASE_MASK |
					   EventMask.POINTER_MOTION_MASK);
			//add_events(EventMask.ALL_EVENTS_MASK);
			//events = 0;
		}

		private void update_uniform_values()
		{
			_delta_time = -_curr_time;
			_curr_time = get_monotonic_time();
			_delta_time += _curr_time;

			if (!paused)
			{
				time = (_curr_time - _start_time) / 1000000.0f;
				_delta = _delta_time / 1000000.0f;
			}
			else
			{
				time = (_pause_time - _start_time) / 1000000.0f;
				_pause_time += (int)(time_slider * _time_slider_factor * _delta_time);
				_delta = 0.0f;
			}

			//stdout.printf("%f\n",time);

			_curr_date = new DateTime.now_local();

			_curr_date.get_ymd(out _year, out _month, out _day);

			_seconds = (float)((_curr_date.get_hour()*60+_curr_date.get_minute())*60)+(float)_curr_date.get_seconds();

			if (_button_pressed)
			{
				glUniform4f(_mouse_loc, (float) _mouse_x, (float) _mouse_y, (float) _button_pressed_x, (float) _button_pressed_y);
			}
			else
			{
				glUniform4f(_mouse_loc, (float) _button_released_x, (float) _button_released_y, -(float) _button_pressed_x, -(float) _button_pressed_y);
			}
		}

		private void render_image(GLuint program)
		{
			if (_initialized)
			{
				_size_mutex.lock();

				while(!_buffer_drawn)
				{
					_draw_cond.wait(_size_mutex);
				}

				update_uniform_values();

				BufferProperties buf_prop = BufferProperties() {
					program = program,

					tex_ids = _tex_ids,

					tex_widths = {},
					tex_heights = {},

					tex_times = {},

					date_loc = _date_loc,
					global_time_loc = _global_time_loc,
					time_loc = _time_loc,
					channel_time_loc = _channel_time_loc,
					delta_loc = _delta_loc,
					fps_loc = _fps_loc,
					frame_loc = _frame_loc,
					res_loc = _res_loc,
					channel_res_loc = _channel_res_loc,
					mouse_loc = _mouse_loc,
					samplerate_loc = _samplerate_loc,
					channel_loc = _channel_loc
				};

				int64 time_delta = render_gl(buf_prop);

				// compute moving average
				if (fps != 0)
				{
					fps = (0.95 * fps + 0.05 * (1000000.0f / time_delta));
				}
				else
				{
					fps = 1000000.0f / time_delta;
				}

				_old_buffer_mutex.lock();
				_old_buffer_rendered = _buffer_rendered;
				_old_buffer = _buffer;
				_old_buffer_mutex.unlock();
				_buffer_mutex.lock();
				glReadPixels(0,0,_width,_height,GL_BGRA,GL_UNSIGNED_BYTE, (GLvoid[])_buffer);

				_buffer_rendered = true;
				_render_cond.signal();

				_buffer_mutex.unlock();

				_size_mutex.unlock();

			}
		}

		private int64 render_gl(BufferProperties buf_prop)
		{
			glViewport(0, 0, _width, _height);

			glUseProgram(buf_prop.program);

			//#TODO: synchronize locations with compiling

			glUniform4f(buf_prop.date_loc, _year, _month, _day, _seconds);
			glUniform1f(buf_prop.global_time_loc, (float)time);
			glUniform1f(buf_prop.time_loc, (float)time);
			glUniform1f(buf_prop.delta_loc, (float)_delta);
			//#TODO: implement proper frame counter
			glUniform1i(buf_prop.frame_loc, (int)(time*60));
			glUniform1f(buf_prop.fps_loc, (float)fps);
			glUniform3f(buf_prop.res_loc, _width, _height, 0);
			glUniform1f(buf_prop.samplerate_loc, _samplerate);

			for(int i=0;i<_num_textures;i++)
			{
				if(buf_prop.channel_loc[i] > 0)
				{
					glActiveTexture(GL_TEXTURE0 + i);
					glBindTexture(GL_TEXTURE_2D, buf_prop.tex_ids[i]);
					glUniform1i(buf_prop.channel_loc[i], (GLint)i);
				}
			}

			glBindVertexArray(_vao[0]);

			glFinish();

			int64 time_before = get_monotonic_time();

			glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

			glFlush();
			glFinish();

			int64 time_after = get_monotonic_time();

			return time_after - time_before;
		}

		private void dummy_render_gl(bool prog_switch)
		{
			if (_initialized)
			{
				glViewport(0, 0, _width, _height);

				if(!prog_switch)
				{
					glUseProgram(_program1);
				}
				else
				{
					glUseProgram(_program2);
				}

				glUniform4f(_date_loc, 0.0f, 0.0f, 0.0f, 0.0f);
				glUniform1f(_global_time_loc, 0.0f);
				glUniform1f(_time_loc, 0.0f);
				glUniform1f(_delta_loc, 0.0f);
				glUniform1i(_frame_loc, 0);
				glUniform1f(_fps_loc, 0.0f);
				glUniform3f(_res_loc, _width, _height, 0);
				glUniform1f(_samplerate_loc, 0.0f);

				glUniform4f(_mouse_loc, 0.0f, 0.0f, 0.0f, 0.0f);

				glBindVertexArray(_vao[0]);

				glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

				glFlush();
				glFinish();

				uchar[] dummy__buffer = new uchar[_width*_height*4];
				glReadPixels(0,0,_width,_height,GL_BGRA,GL_UNSIGNED_BYTE, (GLvoid[])dummy__buffer);
			}
		}
	}
}
