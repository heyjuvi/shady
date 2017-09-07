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
		public signal void pass_compilation_terminated(int pass_index, ShaderError? e);

		struct BufferProperties
		{
			public GLuint program;
			public GLuint fb;

			public GLuint[] tex_ids;

			public GLuint tex_id_out;

			public int[] tex_widths;
			public int[] tex_heights;

			public double[] tex_times;

			public GLint date_loc;
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
		private BufferProperties _image_prop1 = BufferProperties();
		private BufferProperties _image_prop2 = BufferProperties();

		private Mutex _image_prog1_mutex = Mutex();
		private Mutex _image_prog2_mutex = Mutex();

		private BufferProperties[] _buffer_props1 = {};
		private BufferProperties[] _buffer_props2 = {};

		private Mutex _buffer_props1_mutex = Mutex();
		private Mutex _buffer_props2_mutex = Mutex();

		private Mutex[] _buffer_prog1_mutexes;
		private Mutex[] _buffer_prog2_mutexes;

		/* Objects */
		private GlContext _gl_context;
		//private Shader _curr_shader;

		/* Constants */
		private const double _time_slider_factor = 2.0;

		/* OpenGL ids */
		private string[] _channel_string = {"iChannel0", "iChannel1", "iChannel2", "iChannel3"};

		private GLuint _fragment_shader;
		private GLuint[] _vao = { 1337 };

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

		public void compile(Shader new_shader)
		{
			//_curr_shader = new_shader;

			new Thread<int>("compile_thread", () =>
			{

				if(_compile_mutex.trylock())
				{
					_gl_context.thread_context();

					compile_blocking(new_shader);

					_gl_context.free_context();
					_compile_mutex.unlock();

					//_render_switch = !_render_switch;
					_render_switch_cond.signal();
				}

				return 0;
			});
		}

		public void compile_blocking(Shader new_shader)
		{
			string image_source = "";
			int image_index = -1;
			int buffer_count = 0;
			Array<Shader.Input> image_inputs = new Array<Shader.Input>();

			for(int i=0; i<new_shader.renderpasses.length;i++)
			{
				if(new_shader.renderpasses.index(i).type == Shader.RenderpassType.IMAGE)
				{
					//stdout.printf("IMAGE, i:%d\n",i);
					image_source = new_shader.renderpasses.index(i).code;
					image_inputs = new_shader.renderpasses.index(i).inputs;
					image_index = i;
				}
				else if(new_shader.renderpasses.index(i).type == Shader.RenderpassType.BUFFER)
				{
					//stdout.printf("BUFFER, i:%d\n",i);
					buffer_count++;
				}
			}

			if(image_index != -1)
			{
				int num_textures = (int)image_inputs.length;

				_image_prop1.tex_ids = new GLuint[num_textures];
				glGenTextures(num_textures, _image_prop1.tex_ids);
				_image_prop2.tex_ids = _image_prop1.tex_ids;

				for(int i=0;i<num_textures;i++)
				{
					init_input_texture(image_inputs.index(i), _image_prop1.tex_ids[i]);
				}

			}
			else
			{
				print("No image _buffer found!\n");
				return;
			}

			string[] buffer_sources = new string[buffer_count];
			int[] buffer_indices = new int[buffer_count];
			Array<Shader.Input>[] buffer_inputs = new Array<Shader.Input>[buffer_count];

			if(buffer_count>0)
			{
				if(!_program_switch)
				{
					_buffer_props1_mutex.lock();
					_buffer_props1 = new BufferProperties[buffer_count];
					_buffer_prog1_mutexes = new Mutex[buffer_count];
				}
				else
				{
					_buffer_props2_mutex.lock();
					_buffer_props2 = new BufferProperties[buffer_count];
					_buffer_prog2_mutexes = new Mutex[buffer_count];
				}

				GLuint[] fbs = new GLuint[buffer_count];
				glGenFramebuffers(buffer_count, fbs);

				int buffer_index=0;
				for(int i=0; i<new_shader.renderpasses.length;i++)
				{
					if(new_shader.renderpasses.index(i).type == Shader.RenderpassType.BUFFER)
					{
						buffer_indices[buffer_index] = i;
						buffer_sources[buffer_index] = new_shader.renderpasses.index(i).code;
						buffer_inputs[buffer_index] = new_shader.renderpasses.index(i).inputs;
						buffer_index++;
					}
				}

				for(int i=0; i<buffer_count; i++)
				{
					if(!_program_switch)
					{
						_buffer_props1[i].fb = fbs[i];
						_buffer_props1[i].tex_id_out = _image_prop1.tex_ids[0];
						_buffer_props1[i].program = glCreateProgram();
						glAttachShader(_buffer_props1[i].program, _gl_context.vertex_shader);
						glAttachShader(_buffer_props1[i].program, _fragment_shader);

						int num_textures = (int)buffer_inputs.length;

						_buffer_props1[i].tex_ids = new GLuint[num_textures];
						glGenTextures(num_textures, _buffer_props1[i].tex_ids);

						for(int j=0;j<num_textures;j++)
						{
							init_input_texture(buffer_inputs[i].index(j),_buffer_props1[i].tex_ids[j]);
						}

					}
					else
					{
						_buffer_props2[i].fb = fbs[i];
						_buffer_props2[i].tex_id_out = _image_prop1.tex_ids[0];
						_buffer_props2[i].program = glCreateProgram();
						glAttachShader(_buffer_props2[i].program, _gl_context.vertex_shader);
						glAttachShader(_buffer_props2[i].program, _fragment_shader);

						int num_textures = (int)buffer_inputs.length;

						_buffer_props2[i].tex_ids = new GLuint[num_textures];
						glGenTextures(num_textures, _buffer_props2[i].tex_ids);

						for(int j=0;j<num_textures;j++)
						{
							init_input_texture(buffer_inputs[i].index(j),_buffer_props2[i].tex_ids[j]);
						}
					}
				}
			}

			string shader_prefix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/prefix.glsl", 0).get_data());
			string shader_suffix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/suffix.glsl", 0).get_data());

			string full_image_source = shader_prefix + image_source + shader_suffix;

			if(!_program_switch)
			{
				compile_pass(image_index, full_image_source, ref _image_prop1, ref _image_prog1_mutex);
			}
			else
			{
				compile_pass(image_index, full_image_source, ref _image_prop2, ref _image_prog2_mutex);
			}

			for(int i=0;i<buffer_count;i++)
			{
				string full_buffer_source = shader_prefix + buffer_sources[i] + shader_suffix;
				if(!_program_switch)
				{
					compile_pass(buffer_indices[i], full_buffer_source, ref _buffer_props1[i], ref _buffer_prog1_mutexes[i]);
					_buffer_props1_mutex.unlock();
				}
				else
				{
					compile_pass(buffer_indices[i], full_buffer_source, ref _buffer_props2[i], ref _buffer_prog2_mutexes[i]);
					_buffer_props2_mutex.unlock();
				}
			}

			//prevent averaging in of old shader
			fps = 0;

			_program_switch = !_program_switch;

		}

		public void reset_time()
		{
			_start_time = _curr_time;
			_pause_time = _curr_time;
		}

		private void compile_pass(int pass_index, string shader_source, ref BufferProperties buf_prop, ref Mutex prog_mutex)
		{
			string[] source_array = { shader_source, null };

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

					pass_compilation_terminated(pass_index, new ShaderError.COMPILATION((string) log));
				}
				else
				{
					pass_compilation_terminated(pass_index, new ShaderError.COMPILATION("Something went substantially wrong..."));
				}

				return;
			}

			prog_mutex.lock();

			glLinkProgram(buf_prop.program);

			buf_prop.res_loc = glGetUniformLocation(buf_prop.program, "iResolution");
			buf_prop.time_loc = glGetUniformLocation(buf_prop.program, "iTime");
			buf_prop.delta_loc = glGetUniformLocation(buf_prop.program, "iTimeDelta");
			buf_prop.frame_loc = glGetUniformLocation(buf_prop.program, "iFrame");
			buf_prop.fps_loc = glGetUniformLocation(buf_prop.program, "iFrameRate");
			buf_prop.channel_time_loc = glGetUniformLocation(buf_prop.program, "iChannelTime");
			buf_prop.channel_res_loc = glGetUniformLocation(buf_prop.program, "iChannelResolution");
			buf_prop.mouse_loc = glGetUniformLocation(buf_prop.program, "iMouse");

			buf_prop.channel_loc = new GLint[buf_prop.tex_ids.length];

			for(int i=0;i<buf_prop.tex_ids.length;i++)
			{
				buf_prop.channel_loc[i] = glGetUniformLocation(buf_prop.program, _channel_string[i]);
			}

			buf_prop.date_loc = glGetUniformLocation(buf_prop.program, "iDate");
			buf_prop.samplerate_loc = glGetUniformLocation(buf_prop.program, "iSampleRate");

			pass_compilation_terminated(pass_index, null);

			prog_mutex.unlock();

			compilation_finished();
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

					if(thread_switch)
					{
						dummy_render_gl(_image_prop2, _image_prog2_mutex);
					}
					else
					{
						dummy_render_gl(_image_prop1, _image_prog1_mutex);
					}
						prog_mutex.unlock();
						_render_switch = !_render_switch;
					}
				
				render_switch_mutex.unlock();

				prog_mutex.lock();
				if(thread_switch)
				{
					render_image(_image_prop2, _image_prog2_mutex, _buffer_props2, _buffer_props2_mutex, _buffer_prog2_mutexes);
				}
				else
				{
					render_image(_image_prop1, _image_prog1_mutex, _buffer_props1, _buffer_props1_mutex, _buffer_prog1_mutexes);
				}
				prog_mutex.unlock();
			}
		}

		private void init_gl(Shader default_shader)
		{
			_gl_context = new GlContext();
			
			_fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);

			_image_prop1.program = glCreateProgram();
			_image_prop2.program = glCreateProgram();

			_image_prop1.fb = 0;
			_image_prop2.fb = 0;

			glAttachShader(_image_prop1.program, _gl_context.vertex_shader);
			glAttachShader(_image_prop1.program, _fragment_shader);

			glAttachShader(_image_prop2.program, _gl_context.vertex_shader);
			glAttachShader(_image_prop2.program, _fragment_shader);

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

			GLuint attrib = glGetAttribLocation(_image_prop1.program, "v");
			GLuint attrib2 = glGetAttribLocation(_image_prop2.program, "v");

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

			_start_time = get_monotonic_time();

			_initialized = true;

			_gl_context.unbind_context();

			_render_thread1 = new Thread<int>.try("_render_thread1", () =>
			{
				render_thread_func(true, _image_prog2_mutex, _render_switch_mutex1, ref _render_thread1_running);
				return 0;
			});

			_render_thread2 = new Thread<int>.try("_render_thread2", () =>
			{
				render_thread_func(false, _image_prog1_mutex, _render_switch_mutex2, ref _render_thread2_running);
				return 0;
			});

			add_events(EventMask.BUTTON_PRESS_MASK |
					   EventMask.BUTTON_RELEASE_MASK |
					   EventMask.POINTER_MOTION_MASK);
			//add_events(EventMask.ALL_EVENTS_MASK);
			//events = 0;
		}

		private void init_input_texture(Shader.Input input, GLuint tex_id)
		{

			print("new texture\n");

			glBindTexture(GL_TEXTURE_2D, tex_id);

			Gdk.Pixbuf buf = ShadertoyResourceManager.TEXTURE_PIXBUFS[input.resource];

			int format=-1;

			if(buf.get_n_channels() == 3)
			{
				format = GL_RGB;
			}
			else if(buf.get_n_channels() == 4)
			{
				format = GL_RGBA;
			}

			glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, buf.get_width(), buf.get_height(), 0, format, GL_UNSIGNED_BYTE, (GLvoid[])buf.get_pixels());

			if(input.sampler.filter == Shader.FilterMode.NEAREST)
			{
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
			}
			else if(input.sampler.filter == Shader.FilterMode.LINEAR)
			{
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			}
			else if(input.sampler.filter == Shader.FilterMode.MIPMAP)
			{
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
				glGenerateMipmap(GL_TEXTURE_2D);
			}

			if(input.sampler.wrap == Shader.WrapMode.REPEAT)
			{
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
			}
			else if(input.sampler.wrap == Shader.WrapMode.CLAMP)
			{
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
			}

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

		}

		private void render_image(BufferProperties img_prop, Mutex img_prog_mutex, BufferProperties[] buf_props, Mutex buf_prop_mutex, Mutex[] buf_prog_mutexes)
		{
			if (_initialized)
			{
				_size_mutex.lock();

				while(!_buffer_drawn)
				{
					_draw_cond.wait(_size_mutex);
				}

				update_uniform_values();

				if(buf_prop_mutex.trylock()){
					for(int i=0; i<buf_props.length; i++){
						render_gl(buf_props[i], buf_prog_mutexes[i]);
					}
					buf_prop_mutex.unlock();
				}

				int64 time_delta = render_gl(img_prop, img_prog_mutex);

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

		private int64 render_gl(BufferProperties buf_prop, Mutex prog_mutex)
		{
			glBindFramebuffer(GL_FRAMEBUFFER, buf_prop.fb);
			if(buf_prop.fb!=0){
				glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, buf_prop.tex_id_out, 0);
			}

			glViewport(0, 0, _width, _height);

			glUseProgram(buf_prop.program);

			//#TODO: synchronize locations with compiling

			glUniform4f(buf_prop.date_loc, _year, _month, _day, _seconds);
			glUniform1f(buf_prop.time_loc, (float)time);
			glUniform1f(buf_prop.delta_loc, (float)_delta);
			//#TODO: implement proper frame counter
			glUniform1i(buf_prop.frame_loc, (int)(time*60));
			glUniform1f(buf_prop.fps_loc, (float)fps);
			glUniform3f(buf_prop.res_loc, _width, _height, 0);
			glUniform1f(buf_prop.samplerate_loc, _samplerate);

			if (_button_pressed)
			{
				glUniform4f(buf_prop.mouse_loc, (float) _mouse_x, (float) _mouse_y, (float) _button_pressed_x, (float) _button_pressed_y);
			}
			else
			{
				glUniform4f(buf_prop.mouse_loc, (float) _button_released_x, (float) _button_released_y, -(float) _button_pressed_x, -(float) _button_pressed_y);
			}

			for(int i=0;i<buf_prop.tex_ids.length;i++)
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

		private void dummy_render_gl(BufferProperties buf_prop, Mutex prog_mutex)
		{
			if (_initialized)
			{
				glViewport(0, 0, _width, _height);

				glUseProgram(buf_prop.program);

				glUniform4f(buf_prop.date_loc, 0.0f, 0.0f, 0.0f, 0.0f);
				glUniform1f(buf_prop.time_loc, 0.0f);
				glUniform1f(buf_prop.delta_loc, 0.0f);
				glUniform1i(buf_prop.frame_loc, 0);
				glUniform1f(buf_prop.fps_loc, 0.0f);
				glUniform3f(buf_prop.res_loc, _width, _height, 0);
				glUniform1f(buf_prop.samplerate_loc, 0.0f);

				glUniform4f(buf_prop.mouse_loc, 0.0f, 0.0f, 0.0f, 0.0f);

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
