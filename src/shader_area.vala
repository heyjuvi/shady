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
		public signal void initialized();

		public signal void compilation_finished();
		public signal void pass_compilation_terminated(int pass_index, ShaderError? e);

		struct BufferProperties
		{
			public GLuint program;
			public GLuint fb;

			public GLuint[] tex_ids;
			public GLuint[] sampler_ids;
			public GLuint[] tex_targets;
			public int[] tex_channels;

			public GLuint tex_id_out_front;
			public GLuint tex_id_out_back;

			public int[,] tex_out_refs;
			public int[] tex_out_refs_img;

			public int[] tex_widths;
			public int[] tex_heights;
			public int[] tex_depths;

			//public double[] tex_times;

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
			public GLint[] channel_locs;
		}

		struct TextureBufferUnit
		{
			public Shader.InputType type;
			public int index;
			public bool v_flip;
			public int input_id;
			public GLuint[] tex_ids;
			public GLuint target;
			public int width;
			public int height;
			public int depth;
		}

		TextureBufferUnit[] _texture_buffer = {};
		TextureBufferUnit[] _buffer_buffer = {};

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
		private BufferProperties _target_prop = BufferProperties();
		private Mutex _target_prog_mutex = Mutex();

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

		/* Constants */
		private const double _time_slider_factor = 2.0;

		/* OpenGL ids */
		private const string _channel_string = "iChannel";

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

		public ShaderArea()
		{
			realize.connect(() =>
			{
				init_gl(get_default_shader());
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
						print("waiting now\n");
						_render_cond.wait(_buffer_mutex);
						print("not waiting anymore\n");
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

				_gl_context.thread_context();

				glBindTexture(GL_TEXTURE_2D, _image_prop1.tex_id_out_back);
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});

				glBindTexture(GL_TEXTURE_2D, _image_prop2.tex_id_out_back);
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});

				for(int i=0;i<_buffer_buffer.length;i++)
				{
					_buffer_buffer[i].width=_width;
					_buffer_buffer[i].height=_height;
					
					for(int j=0;j<2;j++)
					{
						glBindTexture(GL_TEXTURE_2D, _buffer_buffer[i].tex_ids[j]);
						glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});
					}
				}

				_buffer = new uchar[_stride*_height];
				_buffer_rendered = false;
				_old_buffer_rendered = false;
				_old_buffer_mutex.unlock();
				_buffer_mutex.unlock();
				_size_mutex.unlock();
				_buffer_drawn = true;
				_draw_cond.signal();
			});

			unrealize.connect(() =>
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

		public Shader? get_shader_from_input(Shader.Input input)
		{
			Shader.Renderpass input_renderpass = new Shader.Renderpass();
			input_renderpass.inputs.append_val(input);
			input_renderpass.type = Shader.RenderpassType.IMAGE;

			if (input.resource == null)
			{
				print("Input has no specified resource!\n");
				return null;
			}

			try
			{
				if (input.type == Shader.InputType.TEXTURE)
				{
					input_renderpass.code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/texture_channel_default.glsl", 0).get_data());
				}
				else if (input.type == Shader.InputType.CUBEMAP)
				{
					input_renderpass.code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/cubemap_channel_default.glsl", 0).get_data());
				}
			}
			catch (Error e)
			{
				print("Couldn't load default shader for input type!\n");
				return null;
			}

			Shader input_shader = new Shader();
			input_shader.renderpasses.append_val(input_renderpass);

			return input_shader;
		}

		public void compile_shader_input(Shader.Input input)
		{
			Shader? input_shader = get_shader_from_input(input);

			if (input_shader != null)
			{
				compile(input_shader);
			}
		}

		public void compile_shader_input_no_thread(Shader.Input input)
		{
			Shader? input_shader = get_shader_from_input(input);

			if (input_shader != null)
			{
				compile_no_thread(input_shader);
			}
		}

		public Shader? get_default_shader()
		{
			Shader default_shader = new Shader();
			Shader.Renderpass renderpass = new Shader.Renderpass();

			try
			{
				string default_code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/default.glsl", 0).get_data());
				renderpass.code = default_code;
			}
			catch (Error e)
			{
				print("Couldn't load default shader!\n");
				return null;
			}

			renderpass.type = Shader.RenderpassType.IMAGE;
			renderpass.name = "Image";

			default_shader.renderpasses.append_val(renderpass);

			return default_shader;
		}

		public void compile_default_shader()
		{
			Shader? input_shader = get_default_shader();

			if (input_shader != null)
			{
				compile(input_shader);
			}
		}

		public void compile_default_shader_no_thread()
		{
			Shader? input_shader = get_default_shader();

			if (input_shader != null)
			{
				compile_no_thread(input_shader);
			}
		}

		public void compile(Shader new_shader)
		{
			new Thread<int>("compile_thread", () =>
			{

				if(_compile_mutex.trylock())
				{
					_gl_context.thread_context();

					compile_blocking(new_shader);

					_gl_context.free_context();
					_compile_mutex.unlock();

					_render_switch = !_render_switch;
					_render_switch_cond.signal();
				}

				return 0;
			});
		}

		public void compile_no_thread(Shader new_shader)
		{
			if(_compile_mutex.trylock())
			{
				_gl_context.thread_context();

				compile_blocking(new_shader);

				_gl_context.free_context();
				_compile_mutex.unlock();

				_render_switch = !_render_switch;
				_render_switch_cond.signal();
			}
		}

		private void compile_blocking(Shader new_shader)
		{
			string image_source = "";
			int image_index = -1;
			int buffer_count = 0;
			Array<Shader.Input> image_inputs = new Array<Shader.Input>();

			for(int i=0; i<new_shader.renderpasses.length;i++)
			{
				if(new_shader.renderpasses.index(i).type == Shader.RenderpassType.IMAGE)
				{
					image_source = new_shader.renderpasses.index(i).code;
					image_inputs = new_shader.renderpasses.index(i).inputs;
					image_index = i;
				}
				else if(new_shader.renderpasses.index(i).type == Shader.RenderpassType.BUFFER)
				{
					buffer_count++;
				}
			}

			if(image_index != -1)
			{
				int num_samplers = (int)image_inputs.length;

				_image_prop1.sampler_ids = new GLuint[num_samplers];
				glGenSamplers(num_samplers, _image_prop1.sampler_ids);

				_image_prop2.sampler_ids = new GLuint[num_samplers];
				glGenSamplers(num_samplers, _image_prop2.sampler_ids);

				_image_prop1.tex_channels = new int[num_samplers];
				_image_prop2.tex_channels = new int[num_samplers];

				_image_prop1.tex_ids = new uint[num_samplers];
				_image_prop2.tex_ids = new uint[num_samplers];

				_image_prop1.tex_targets = new uint[num_samplers];
				_image_prop2.tex_targets = new uint[num_samplers];

				_image_prop1.tex_widths = {0,0,0,0};
				_image_prop2.tex_widths = {0,0,0,0};

				_image_prop1.tex_heights = {0,0,0,0};
				_image_prop2.tex_heights = {0,0,0,0};

				_image_prop1.tex_depths = {0,0,0,0};
				_image_prop2.tex_depths = {0,0,0,0};

				GLuint[] fb_arr = {0};
				glGenFramebuffers(1, fb_arr);

				_image_prop1.fb = fb_arr[0];
				_image_prop2.fb = fb_arr[0];

				//_image_prop1.fb = 0;
				//_image_prop2.fb = 0;

				GLuint[] tex_arr = {0};
				glGenTextures(1, tex_arr);

				_image_prop1.tex_id_out_back = tex_arr[0];
				_image_prop2.tex_id_out_back = tex_arr[0];

				glBindTexture(GL_TEXTURE_2D, tex_arr[0]);
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});

				glBindTexture(GL_TEXTURE_2D, tex_arr[1]);
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});

				for(int i=0;i<image_inputs.length;i++)
				{
					int width, height, depth, channel;

					init_sampler(image_inputs.index(i), _image_prop1.sampler_ids[i]);

					GLuint tex_target;
					GLuint[] tex_ids = query_input_texture(image_inputs.index(i), out width, out height, out depth, out tex_target);
					_image_prop1.tex_ids[i] = tex_ids[0];
					_image_prop1.tex_targets[i] = tex_target;

					channel = image_inputs.index(i).channel;
					_image_prop1.tex_channels[i] = channel;

					if(channel>=0 && channel<4){
						_image_prop1.tex_widths[channel] = width;
						_image_prop1.tex_heights[channel] = height;
						_image_prop1.tex_depths[channel] = depth;
					}

					init_sampler(image_inputs.index(i), _image_prop2.sampler_ids[i]);

					tex_ids = query_input_texture(image_inputs.index(i), out width, out height, out depth, out tex_target);
					_image_prop2.tex_ids[i] = tex_ids[0];
					_image_prop2.tex_targets[i] = tex_target;

					channel = image_inputs.index(i).channel;
					_image_prop2.tex_channels[i] = channel;

					if(channel>=0 && channel<4){
						_image_prop2.tex_widths[channel] = width;
						_image_prop2.tex_heights[channel] = height;
						_image_prop2.tex_depths[channel] = depth;
					}
				}

				_target_prop.sampler_ids = new GLuint[1];
				glGenSamplers(1, _target_prop.sampler_ids);
				Shader.Input target_input = new Shader.Input();
				target_input.sampler = new Shader.Sampler();
				target_input.sampler.filter = Shader.FilterMode.LINEAR;
				target_input.sampler.wrap = Shader.WrapMode.REPEAT;
				init_sampler(target_input, _target_prop.sampler_ids[0]);
				_target_prop.tex_widths = new int[4];
				_target_prop.tex_heights = new int[4];
				_target_prop.tex_depths = new int[4];
				_target_prop.tex_channels = {0};
				_target_prop.tex_ids = {_image_prop1.tex_id_out_back};
				_target_prop.tex_targets = {GL_TEXTURE_2D};
				_target_prop.fb = 0;
			}
			else
			{
				print("No image _buffer found!\n");
				return;
			}

			string[] buffer_sources = new string[buffer_count];
			int[] buffer_indices = new int[buffer_count];
			Array<Shader.Input>[] buffer_inputs = new Array<Shader.Input>[buffer_count];
			Shader.Output[] buffer_outputs = new Shader.Output[buffer_count];

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
						buffer_outputs[buffer_index] = new_shader.renderpasses.index(i).outputs.index(0);
						buffer_index++;
					}
				}

				for(int i=0; i<buffer_count; i++)
				{
					if(!_program_switch)
					{
						_buffer_props1[i].fb = fbs[i];

						GLuint[] output_tex_ids = query_output_texture(buffer_outputs[i]);
						_buffer_props1[i].tex_id_out_front = output_tex_ids[0];
						_buffer_props1[i].tex_id_out_back = output_tex_ids[1];

						glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fbs[i]);
						glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, output_tex_ids[1], 0);

						glClearColor(0,0,0,1);
						glClear(GL_COLOR_BUFFER_BIT);

						_buffer_props1[i].program = glCreateProgram();
						glAttachShader(_buffer_props1[i].program, _gl_context.vertex_shader);
						glAttachShader(_buffer_props1[i].program, _fragment_shader);

						int num_samplers = (int)buffer_inputs[i].length;

						_buffer_props1[i].sampler_ids = new GLuint[num_samplers];
						glGenSamplers(num_samplers, _buffer_props1[i].sampler_ids);

						_buffer_props1[i].tex_widths = {0,0,0,0};
						_buffer_props1[i].tex_heights = {0,0,0,0};
						_buffer_props1[i].tex_depths = {0,0,0,0};

						_buffer_props1[i].tex_channels = new int[num_samplers];
						_buffer_props1[i].tex_ids = new uint[num_samplers];
						_buffer_props1[i].tex_targets = new uint[num_samplers];

						for(int j=0;j<num_samplers;j++)
						{
							int width, height, depth, channel;

							init_sampler(buffer_inputs[i].index(j), _buffer_props1[i].sampler_ids[j]);

							GLuint tex_target;
							GLuint[] tex_ids = query_input_texture(buffer_inputs[i].index(j), out width, out height, out depth, out tex_target);
							_buffer_props1[i].tex_targets[j] = tex_target;
							_buffer_props1[i].tex_ids[j] = tex_ids[0];

							channel = buffer_inputs[i].index(j).channel;
							_buffer_props1[i].tex_channels[j] = channel;

							if(channel>=0 && channel<4){
								_buffer_props1[i].tex_widths[channel] = width;
								_buffer_props1[i].tex_heights[channel] = height;
								_buffer_props1[i].tex_depths[channel] = depth;
							}
						}

					}
					else
					{
						_buffer_props2[i].fb = fbs[i];

						GLuint[] output_tex_ids = query_output_texture(buffer_outputs[i]);
						_buffer_props2[i].tex_id_out_front = output_tex_ids[0];
						_buffer_props2[i].tex_id_out_back = output_tex_ids[1];

						_buffer_props2[i].program = glCreateProgram();
						glAttachShader(_buffer_props2[i].program, _gl_context.vertex_shader);
						glAttachShader(_buffer_props2[i].program, _fragment_shader);

						int num_samplers = (int)buffer_inputs[i].length;

						_buffer_props2[i].sampler_ids = new GLuint[num_samplers];
						glGenSamplers(num_samplers, _buffer_props2[i].sampler_ids);

						_buffer_props2[i].tex_widths = {0,0,0,0};
						_buffer_props2[i].tex_heights = {0,0,0,0};
						_buffer_props2[i].tex_depths = {0,0,0,0};

						_buffer_props2[i].tex_channels = new int[num_samplers];
						_buffer_props2[i].tex_ids = new uint[num_samplers];
						_buffer_props2[i].tex_targets = new uint[num_samplers];

						for(int j=0;j<num_samplers;j++)
						{
							int width, height, depth, channel;

							init_sampler(buffer_inputs[i].index(j), _buffer_props2[i].sampler_ids[j]);

							GLuint tex_target;
							GLuint[] tex_ids = query_input_texture(buffer_inputs[i].index(j), out width, out height, out depth, out tex_target);
							_buffer_props2[i].tex_targets[j] = tex_target;
							_buffer_props2[i].tex_ids[j] = tex_ids[0];

							channel = buffer_inputs[i].index(j).channel;
							_buffer_props2[i].tex_channels[j] = channel;

							if(channel>=0 && channel<4){
								_buffer_props2[i].tex_widths[channel] = width;
								_buffer_props2[i].tex_heights[channel] = height;
								_buffer_props2[i].tex_depths[channel] = depth;
							}
						}
					}
				}

				for(int i=0;i<buffer_count;i++)
				{
					if(!_program_switch)
					{
						int num_refs = 0;
						for(int j=0;j<buffer_count;j++)
						{
							for(int k=0;k<_buffer_props1[j].tex_ids.length;k++)
							{
								if(_buffer_props1[j].tex_ids[k] == _buffer_props1[i].tex_id_out_front)
								{
									num_refs++;
								}
							}
						}

						_buffer_props1[i].tex_out_refs = new int[num_refs,2];
						int ref_index=0;
						for(int j=0;j<buffer_count;j++)
						{
							for(int k=0;k<_buffer_props1[j].tex_ids.length;k++)
							{
								if(_buffer_props1[j].tex_ids[k] == _buffer_props1[i].tex_id_out_front)
								{
									_buffer_props1[i].tex_out_refs[ref_index,0] = j;
									_buffer_props1[i].tex_out_refs[ref_index,1] = k;
								}
							}
						}

						_buffer_props1[i].tex_out_refs_img = {};
						for(int j=0;j<_image_prop1.tex_ids.length;j++)
						{
							if(_image_prop1.tex_ids[j] == _buffer_props1[i].tex_id_out_front)
							{
								_buffer_props1[i].tex_out_refs_img += j;
							}
						}
					}
					else
					{
						int num_refs = 0;
						for(int j=0;j<buffer_count;j++)
						{
							for(int k=0;k<_buffer_props2[j].tex_ids.length;k++)
							{
								if(_buffer_props2[j].tex_ids[k] == _buffer_props2[i].tex_id_out_front)
								{
									num_refs++;
								}
							}
						}

						_buffer_props2[i].tex_out_refs = new int[num_refs,2];
						int ref_index=0;
						for(int j=0;j<buffer_count;j++)
						{
							for(int k=0;k<_buffer_props2[j].tex_ids.length;k++)
							{
								if(_buffer_props2[j].tex_ids[k] == _buffer_props2[i].tex_id_out_front)
								{
									_buffer_props2[i].tex_out_refs[ref_index,0] = j;
									_buffer_props2[i].tex_out_refs[ref_index,1] = k;
								}
							}
						}

						_buffer_props2[i].tex_out_refs_img = {};
						for(int j=0;j<_image_prop2.tex_ids.length;j++)
						{
							if(_image_prop2.tex_ids[j] == _buffer_props2[i].tex_id_out_front)
							{
								_buffer_props2[i].tex_out_refs_img += j;
							}
						}
					}
				}
			}

			try{
				string shader_prefix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/prefix.glsl", 0).get_data());
				string shader_suffix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/suffix.glsl", 0).get_data());

				string target_source = (string) (resources_lookup_data("/org/hasi/shady/data/shader/texture_channel_default.glsl", 0).get_data());
				string target_channel_prefix = "uniform sampler2D iChannel0;\n";

				string full_target_source = shader_prefix + target_channel_prefix + target_source + shader_suffix;

				compile_pass(-1, full_target_source, ref _target_prop, ref _target_prog_mutex);

				string image_channel_prefix = "";

				for(int i=0;i<image_inputs.length;i++)
				{
					int index = image_inputs.index(i).channel;
					if(image_inputs.index(i).type == Shader.InputType.TEXTURE || image_inputs.index(i).type == Shader.InputType.BUFFER)
					{
						image_channel_prefix += "uniform sampler2D " + _channel_string + @"$index;\n";
					}
					else if(image_inputs.index(i).type == Shader.InputType.3DTEXTURE)
					{
						image_channel_prefix += "uniform sampler3D " + _channel_string + @"$index;\n";
					}
					else if(image_inputs.index(i).type == Shader.InputType.CUBEMAP)
					{
						image_channel_prefix += "uniform samplerCube " + _channel_string + @"$index;\n";
					}
				}

				string full_image_source = shader_prefix + image_channel_prefix + image_source + shader_suffix;

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
					string buffer_channel_prefix = "";

					for(int j=0;j<buffer_inputs[i].length;j++)
					{
						int index = buffer_inputs[i].index(j).channel;
						if(buffer_inputs[i].index(j).type == Shader.InputType.TEXTURE ||
						   buffer_inputs[i].index(j).type == Shader.InputType.BUFFER)
						{
							buffer_channel_prefix += "uniform sampler2D " + _channel_string + @"$index;\n";
						}
						else if(buffer_inputs[i].index(j).type == Shader.InputType.3DTEXTURE)
						{
							buffer_channel_prefix += "uniform sampler3D " + _channel_string + @"$index;\n";
						}
						else if(buffer_inputs[i].index(j).type == Shader.InputType.CUBEMAP)
						{
							buffer_channel_prefix += "uniform samplerCube " + _channel_string + @"$index;\n";
						}
					}

					string full_buffer_source = shader_prefix + buffer_channel_prefix + buffer_sources[i] + shader_suffix;

					if(!_program_switch)
					{
						compile_pass(buffer_indices[i], full_buffer_source, ref _buffer_props1[i], ref _buffer_prog1_mutexes[i]);
					}
					else
					{
						compile_pass(buffer_indices[i], full_buffer_source, ref _buffer_props2[i], ref _buffer_prog2_mutexes[i]);
					}
				}

				if(buffer_count>0)
				{
					if(!_program_switch)
					{
						_buffer_props1_mutex.unlock();
					}
					else
					{
						_buffer_props2_mutex.unlock();
					}
				}
			}
			catch(Error e){
				print("Couldn't load shader prefix or suffix\n");
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

			buf_prop.channel_locs = new GLint[buf_prop.tex_ids.length];

			for(int i=0;i<buf_prop.tex_ids.length;i++)
			{
				buf_prop.channel_locs[i] = glGetUniformLocation(buf_prop.program, _channel_string+@"$i");
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

			_target_prop.program = glCreateProgram();

			_image_prop1.program = glCreateProgram();
			_image_prop2.program = glCreateProgram();

			glAttachShader(_target_prop.program, _gl_context.vertex_shader);
			glAttachShader(_target_prop.program, _fragment_shader);

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

			GLuint attrib0 = glGetAttribLocation(_target_prop.program, "v");
			GLuint attrib1 = glGetAttribLocation(_image_prop1.program, "v");
			GLuint attrib2 = glGetAttribLocation(_image_prop2.program, "v");

			glEnableVertexAttribArray(attrib0);
			glVertexAttribPointer(attrib0, 2, GL_FLOAT, (GLboolean) GL_FALSE, 0, null);

			glEnableVertexAttribArray(attrib1);
			glVertexAttribPointer(attrib1, 2, GL_FLOAT, (GLboolean) GL_FALSE, 0, null);

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

			glEnableVertexAttribArray(attrib0);
			glVertexAttribPointer(attrib0, 2, GL_FLOAT, (GLboolean) GL_FALSE, 0, null);

			glEnableVertexAttribArray(attrib1);
			glVertexAttribPointer(attrib1, 2, GL_FLOAT, (GLboolean) GL_FALSE, 0, null);

			glEnableVertexAttribArray(attrib2);
			glVertexAttribPointer(attrib2, 2, GL_FLOAT, (GLboolean) GL_FALSE, 0, null);

			glBindBuffer(GL_ARRAY_BUFFER, 0);
			glBindVertexArray(0);

			glDeleteBuffers(1, vbo);

			_start_time = get_monotonic_time();

			_initialized = true;

			_gl_context.unbind_context();

			try{
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
			}
			catch(Error e){
				print("Couldn't start render threads\n");
			}

			add_events(EventMask.BUTTON_PRESS_MASK |
					   EventMask.BUTTON_RELEASE_MASK |
					   EventMask.POINTER_MOTION_MASK);
			//add_events(EventMask.ALL_EVENTS_MASK);
			//events = 0;

			int error = (int)glGetError();
			if(error!=0){
				print(@"init gl error:$(error)\n");
			}

			initialized();
		}

		private GLuint[] query_input_texture(Shader.Input input, out int width, out int height, out int depth, out uint target)
		{

			width = 0;
			height = 0;
			depth = 0;
			target = -1;

			int i;

			if(input.type == Shader.InputType.BUFFER)
			{
				for(i=0;i<_buffer_buffer.length;i++)
				{
				    if(_buffer_buffer[i].type == Shader.InputType.BUFFER && _buffer_buffer[i].input_id == input.id)
					{
						width = _buffer_buffer[i].width;
						height = _buffer_buffer[i].height;
						depth = _buffer_buffer[i].depth;
						target = _buffer_buffer[i].target;
						return _buffer_buffer[i].tex_ids;
					}
				}
				if(i == _buffer_buffer.length)
				{
					GLuint[] tex_ids = init_input_texture(input, out width, out height, out depth, out target);
					TextureBufferUnit tex_unit = TextureBufferUnit()
					{
						width = width,
						height = height,
						depth = depth,
						target = target,
						input_id = input.id,
						tex_ids = tex_ids,
						type = input.type,
						v_flip = input.sampler.v_flip,
						index = i
					};

					_buffer_buffer += tex_unit;
					return tex_ids;
				}
			}
			else
			{
				for(i=0;i<_texture_buffer.length;i++)
				{
					if(input.type == _texture_buffer[i].type &&
					   _texture_buffer[i].index == input.resource_index &&
					   _texture_buffer[i].v_flip == input.sampler.v_flip)
					{
						width = _texture_buffer[i].width;
						height = _texture_buffer[i].height;
						depth = _texture_buffer[i].depth;
						target = _texture_buffer[i].target;
						return _texture_buffer[i].tex_ids;
					}
				}

				if(i == _texture_buffer.length)
				{
					GLuint[] tex_ids = init_input_texture(input, out width, out height, out depth, out target);
					TextureBufferUnit tex_unit = TextureBufferUnit()
					{
						width = width,
						height = height,
						depth = depth,
						target = target,
						input_id = input.id,
						tex_ids = tex_ids,
						type = input.type,
						v_flip = input.sampler.v_flip,
						index = i
					};

					_texture_buffer += tex_unit;
					return tex_ids;
				}
			}
			return {};
		}

		private GLuint[] query_output_texture(Shader.Output output)
		{
			int i;
			for(i=0;i<_buffer_buffer.length;i++)
			{
				if(_buffer_buffer[i].type == Shader.InputType.BUFFER &&
				   _buffer_buffer[i].input_id == output.id)
				{
					return _buffer_buffer[i].tex_ids;
				}
			}

			if(i == _buffer_buffer.length)
			{
				Shader.Input input = new Shader.Input();
				input.id = output.id;
				input.type = Shader.InputType.BUFFER;

				int width, height, depth;
				uint target;

				GLuint[] tex_ids = init_input_texture(input, out width, out height, out depth, out target);
				TextureBufferUnit tex_unit = TextureBufferUnit()
				{
					width = width,
					height = height,
					depth = depth,
					target = target,
					input_id = input.id,
					tex_ids = tex_ids,
					type = input.type,
					v_flip = input.sampler.v_flip,
					index = i
				};

				_buffer_buffer += tex_unit;
				return tex_ids;
			}
			return {};
		}

		private GLuint[] init_input_texture(Shader.Input input, out int width, out int height, out int depth, out uint target)
		{
			width=0;
			height=0;
			depth=0;

			target = -1;

			GLuint[] tex_ids = {};

			if(input.type == Shader.InputType.TEXTURE)
			{
				target = GL_TEXTURE_2D;
				tex_ids = {0};
				glGenTextures(1,tex_ids);
				glBindTexture(target, tex_ids[0]);

				Gdk.Pixbuf buf = ShadertoyResourceManager.TEXTURE_PIXBUFS[input.resource_index];

				if(input.sampler.v_flip)
				{
					buf = buf.flip(false);
				}

				width = buf.get_width();
				height = buf.get_height();

				int format=-1;
				if(buf.get_n_channels() == 3)
				{
					format = GL_RGB;
				}
				else if(buf.get_n_channels() == 4)
				{
					format = GL_RGBA;
				}

				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])buf.get_pixels());

				glGenerateMipmap(target);
			}
			else if(input.type == Shader.InputType.3DTEXTURE)
			{
				target = GL_TEXTURE_3D;
				tex_ids = {0};
				glGenTextures(1,tex_ids);
				glBindTexture(target, tex_ids[0]);

				ShadertoyResourceManager.Voxmap voxmap = ShadertoyResourceManager.3DTEXTURE_BUFFERS[input.resource_index];

				width = voxmap.width;
				height = voxmap.height;
				depth = voxmap.depth;

				int format=-1;
				if(voxmap.channels == 3)
				{
					format = GL_RGB;
				}
				else if(voxmap.channels == 4)
				{
					format = GL_RGBA;
				}

				glTexImage3D(GL_TEXTURE_3D, 0, GL_RGBA, width, height, depth, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])voxmap.voxels);
				glGenerateMipmap(target);
			}
			else if(input.type == Shader.InputType.CUBEMAP)
			{
				target = GL_TEXTURE_CUBE_MAP;
				tex_ids = {0};
				glGenTextures(1,tex_ids);
				glBindTexture(target, tex_ids[0]);

				Gdk.Pixbuf buf = ShadertoyResourceManager.CUBEMAP_PIXBUFS_ARRAY[input.resource_index,0];

				if(input.sampler.v_flip)
				{
					buf = buf.flip(false);
				}

				width = buf.get_width();
				height = buf.get_height();

				int format=-1;
				if(buf.get_n_channels() == 3)
				{
					format = GL_RGB;
				}
				else if(buf.get_n_channels() == 4)
				{
					format = GL_RGBA;
				}

				glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])buf.get_pixels());
				buf = ShadertoyResourceManager.CUBEMAP_PIXBUFS_ARRAY[input.resource_index,1];

				if(input.sampler.v_flip)
				{
					buf = buf.flip(false);
				}

				glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])buf.get_pixels());
				buf = ShadertoyResourceManager.CUBEMAP_PIXBUFS_ARRAY[input.resource_index,2];

				if(input.sampler.v_flip)
				{
					buf = buf.flip(false);
				}


				glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])buf.get_pixels());
				buf = ShadertoyResourceManager.CUBEMAP_PIXBUFS_ARRAY[input.resource_index,3];

				if(input.sampler.v_flip)
				{
					buf = buf.flip(false);
				}

				glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])buf.get_pixels());
				buf = ShadertoyResourceManager.CUBEMAP_PIXBUFS_ARRAY[input.resource_index,4];

				if(input.sampler.v_flip)
				{
					buf = buf.flip(false);
				}


				glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])buf.get_pixels());
				buf = ShadertoyResourceManager.CUBEMAP_PIXBUFS_ARRAY[input.resource_index,5];

				if(input.sampler.v_flip)
				{
					buf = buf.flip(false);
				}

				glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])buf.get_pixels());
				glGenerateMipmap(target);
			}
			else if(input.type == Shader.InputType.BUFFER)
			{
				target = GL_TEXTURE_2D;
				tex_ids = {0, 0};
				glGenTextures(2,tex_ids);

				width = _width;
				height = _height;

				for(int i=0;i<2;i++)
				{
					glBindTexture(target, tex_ids[i]);
					glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});
				}
			}
			return tex_ids;
		}

		private void init_sampler(Shader.Input input, GLuint sampler_id)
		{
			if(input.sampler.filter == Shader.FilterMode.NEAREST)
			{
				glSamplerParameteri(sampler_id, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
				glSamplerParameteri(sampler_id, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
			}
			else if(input.sampler.filter == Shader.FilterMode.LINEAR)
			{
				glSamplerParameteri(sampler_id, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
				glSamplerParameteri(sampler_id, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			}
			else if(input.sampler.filter == Shader.FilterMode.MIPMAP)
			{
				glSamplerParameteri(sampler_id, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
				glSamplerParameteri(sampler_id, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
			}

			if(input.sampler.wrap == Shader.WrapMode.REPEAT)
			{
				glSamplerParameteri(sampler_id, GL_TEXTURE_WRAP_S, GL_REPEAT);
				glSamplerParameteri(sampler_id, GL_TEXTURE_WRAP_T, GL_REPEAT);
			}
			else if(input.sampler.wrap == Shader.WrapMode.CLAMP)
			{
				glSamplerParameteri(sampler_id, GL_TEXTURE_WRAP_S, GL_CLAMP);
				glSamplerParameteri(sampler_id, GL_TEXTURE_WRAP_T, GL_CLAMP);
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

				if(buf_prop_mutex.trylock())
				{
					for(int i=0; i<buf_props.length; i++)
					{
						render_gl(buf_props[i], buf_prog_mutexes[i]);
					}

					for(int i=0; i<buf_props.length; i++)
					{
						uint tmp = buf_props[i].tex_id_out_back;
						buf_props[i].tex_id_out_back = buf_props[i].tex_id_out_front;
						buf_props[i].tex_id_out_front = tmp;
						for(int j=0; j<buf_props[i].tex_out_refs.length[0]; j++)
						{
							buf_props[buf_props[i].tex_out_refs[j,0]].tex_ids[buf_props[i].tex_out_refs[j,1]] = tmp;
						}

						for(int j=0; j<buf_props[i].tex_out_refs_img.length; j++)
						{
							img_prop.tex_ids[buf_props[i].tex_out_refs_img[j]] = tmp;
						}
					}

					buf_prop_mutex.unlock();
				}

				int error = (int)glGetError();
				if(error!=0){
					print(@"draw gl error:$(error)\n");
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

				render_target();

			}
		}

		private void render_target()
		{
			render_gl(_target_prop, _target_prog_mutex);

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

		private int64 render_gl(BufferProperties buf_prop, Mutex prog_mutex)
		{
			glBindFramebuffer(GL_DRAW_FRAMEBUFFER, buf_prop.fb);
			if(buf_prop.fb!=0){
				glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, buf_prop.tex_id_out_back, 0);
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
			float[] channel_res = {(float)buf_prop.tex_widths[0],(float)buf_prop.tex_heights[0],(float)buf_prop.tex_depths[0],
			                       (float)buf_prop.tex_widths[1],(float)buf_prop.tex_heights[1],(float)buf_prop.tex_depths[1],
			                       (float)buf_prop.tex_widths[2],(float)buf_prop.tex_heights[2],(float)buf_prop.tex_depths[2],
			                       (float)buf_prop.tex_widths[3],(float)buf_prop.tex_heights[3],(float)buf_prop.tex_depths[3]};
			glUniform3fv(buf_prop.channel_res_loc, 4, channel_res);
			glUniform1f(buf_prop.samplerate_loc, _samplerate);

			if (_button_pressed)
			{
				glUniform4f(buf_prop.mouse_loc, (float) _mouse_x, (float) _mouse_y, (float) _button_pressed_x, (float) _button_pressed_y);
			}
			else
			{
				glUniform4f(buf_prop.mouse_loc, (float) _button_released_x, (float) _button_released_y, -(float) _button_pressed_x, -(float) _button_pressed_y);
			}

			for(int i=0;i<buf_prop.tex_ids.length && i<buf_prop.channel_locs.length;i++)
			{
				if(buf_prop.channel_locs[i] >= 0)
				{
					glActiveTexture(GL_TEXTURE0 + buf_prop.tex_channels[i]);
					glBindTexture(buf_prop.tex_targets[i], buf_prop.tex_ids[i]);
					glBindSampler(buf_prop.tex_channels[i], buf_prop.sampler_ids[i]);
					glUniform1i(buf_prop.channel_locs[i], (GLint)buf_prop.tex_channels[i]);
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
				float[] channel_res = new float[12];
				glUniform3fv(buf_prop.channel_res_loc, 4, channel_res);
				glUniform1f(buf_prop.samplerate_loc, 0.0f);

				glUniform4f(buf_prop.mouse_loc, 0.0f, 0.0f, 0.0f, 0.0f);

				glBindVertexArray(_vao[0]);

				glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

				glFlush();
				glFinish();

				uchar[] dummy_buffer = new uchar[_width*_height*4];
				glReadPixels(0,0,_width,_height,GL_BGRA,GL_UNSIGNED_BYTE, (GLvoid[])dummy_buffer);
			}
		}
	}
}
