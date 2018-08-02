using GL;
using Gtk;
using Gdk;

namespace Shady
{
	public class ShaderArea : GLArea
	{
		public signal void initialized();

		public signal void compilation_finished();
		public signal void pass_compilation_terminated(int pass_index, ShaderError? e);

		struct BufferProperties
		{
			public GLuint program;
			public GLuint fb;
			public GLuint vao;

			public Gdk.GLContext context;

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

		public double fps { get; private set; }
		public double time { get; private set; }

		/* Buffer properties structs*/
		private BufferProperties _target_prop = BufferProperties();

		/* OpenGL ids */
		private const string _channel_string = "iChannel";

		private GLuint _vertex_shader;
		private GLuint _fragment_shader;

		private GLuint _resize_fb;

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

		private bool _size_updated = false;

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

		private Mutex _size_mutex = Mutex();

		public ShaderArea()
		{
			realize.connect(() =>
			{
				init_gl(get_default_shader());

				print("REALIZE: " + get_window().get_type().name() + "\n\n\n");
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

			create_context.connect(() =>
			{
				try
				{
					return get_window().create_gl_context();
				}
				catch(Error e)
				{
					print("Couldn't create gl context\n");
					return (Gdk.GLContext)null;
				}
			});

			render.connect(() =>
			{
				_size_mutex.lock();
				update_uniform_values();
				render_gl(_target_prop);
				_size_mutex.unlock();
				queue_draw();
				return false;
			});

			resize.connect((width, height) =>
			{
				_size_mutex.lock();

				_width = width;
				_height = height;

				_size_updated = true;

				if(!_initialized)
				{
					_initialized = true;
					initialized();
				}

				_size_mutex.unlock();
			});

			unrealize.connect(() =>
			{
				print("UNREALIZE: " + get_window().get_type().name() + "\n\n\n");
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
				else if (input.type == Shader.InputType.3DTEXTURE)
				{
					input_renderpass.code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/3dtexture_channel_default.glsl", 0).get_data());
				}
			}
			catch(Error e)
			{
				print("Couldn't load default shader for input type!\n");
				return null;
			}

			Shader input_shader = new Shader();
			input_shader.renderpasses.append_val(input_renderpass);

			return input_shader;
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
			catch(Error e)
			{
				print("Couldn't load default shader!\n");
				return null;
			}

			renderpass.type = Shader.RenderpassType.IMAGE;
			renderpass.name = "Image";

			default_shader.renderpasses.append_val(renderpass);

			return default_shader;
		}

		public void compile_shader_input(Shader.Input input)
		{
			if(input.resource!=null){
				_target_prop.context.make_current();
				int width, height, depth, channel;
				GLuint tex_target;

				init_sampler(input, _target_prop.sampler_ids[0]);

				GLuint[] tex_ids = query_input_texture(input, out width, out height, out depth, out tex_target);

				if(tex_ids != null && tex_ids.length > 0){

					Shader? input_shader = get_shader_from_input(input);

					string shader_prefix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/prefix.glsl", 0).get_data());
					string shader_suffix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/suffix.glsl", 0).get_data());

					string target_source = input_shader.renderpasses.index(0).code;

					string target_channel_prefix = "";

					if(input.type == Shader.InputType.TEXTURE)
					{
						target_channel_prefix += "uniform sampler2D iChannel0;\n";
					}
					else if(input.type == Shader.InputType.3DTEXTURE)
					{
						target_channel_prefix += "uniform sampler3D iChannel0;\n";
					}
					else if(input.type == Shader.InputType.CUBEMAP)
					{
						target_channel_prefix += "uniform samplerCube iChannel0;\n";
					}

					string full_target_source = shader_prefix + target_channel_prefix + target_source + shader_suffix;

					compile_pass(-1, full_target_source, ref _target_prop);

					_target_prop.tex_ids[0] = tex_ids[0];
					_target_prop.tex_targets[0] = tex_target;

					channel = input.channel;

					_target_prop.tex_channels[0] = channel;

					if(channel>=0 && channel<4){
						_target_prop.tex_widths[channel] = width;
						_target_prop.tex_heights[channel] = height;
						_target_prop.tex_depths[channel] = depth;
					}
				}
			}
		}

		private void compile_pass(int pass_index, string shader_source, ref BufferProperties buf_prop)
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

			compilation_finished();
		}

		private void init_gl(Shader default_shader)
		{
			make_current();

			try
			{
				string vertex_source = (string) (resources_lookup_data("/org/hasi/shady/data/shader/vertex.glsl", 0).get_data());
				string[] vertex_source_array = { vertex_source, null };

				_vertex_shader = glCreateShader(GL_VERTEX_SHADER);
				glShaderSource(_vertex_shader, 1, vertex_source_array, null);
				glCompileShader(_vertex_shader);
			}
			catch(Error e)
			{
				print("Couldn't load vertex shader\n");
			}

			GLuint[] tex_arr = {0};
			glGenTextures(1, tex_arr);

			glBindTexture(GL_TEXTURE_2D, tex_arr[0]);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});

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
			_target_prop.tex_ids = {tex_arr[0]};
			_target_prop.tex_widths = {0,0,0,0};
			_target_prop.tex_heights = {0,0,0,0};
			_target_prop.tex_depths = {0,0,0,0};
			_target_prop.tex_ids = {tex_arr[0]};
			_target_prop.tex_targets = {GL_TEXTURE_2D};
			_target_prop.fb = 0;

			_target_prop.program = glCreateProgram();
			_target_prop.context = get_context();

			_fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);

			glAttachShader(_target_prop.program, _vertex_shader);
			glAttachShader(_target_prop.program, _fragment_shader);

			try
			{
				string shader_prefix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/prefix.glsl", 0).get_data());
				string shader_suffix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/suffix.glsl", 0).get_data());

				string target_source = (string) (resources_lookup_data("/org/hasi/shady/data/shader/texture_channel_default.glsl", 0).get_data());

				string target_channel_prefix = "uniform sampler2D iChannel0;\n";

				string full_target_source = shader_prefix + target_channel_prefix + target_source + shader_suffix;

				compile_pass(-1, full_target_source, ref _target_prop);
			}
			catch(Error e)
			{
				print("Couldn't load target shader sources\n");
			}

			GLuint[] vao_arr = {0};

			glGenVertexArrays(1, vao_arr);
			glBindVertexArray(vao_arr[0]);
			_target_prop.vao = vao_arr[0];

			GLuint[] vbo = {0};
			glGenBuffers(1, vbo);

			GLfloat[] vertices = { -1, -1,
								    3, -1,
								   -1,  3 };

			glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
			glBufferData(GL_ARRAY_BUFFER, vertices.length * sizeof (GLfloat), (GLvoid[]) vertices, GL_STATIC_DRAW);

			GLuint attrib0 = glGetAttribLocation(_target_prop.program, "v");

			glEnableVertexAttribArray(attrib0);
			glVertexAttribPointer(attrib0, 2, GL_FLOAT, (GLboolean) GL_FALSE, 0, null);

			glBindBuffer(GL_ARRAY_BUFFER, 0);
			glBindVertexArray(0);

			_start_time = get_monotonic_time();

			Gdk.GLContext.clear_current();
		}

		private GLuint[] query_input_texture(Shader.Input input, out int width, out int height, out int depth, out uint target)
		{

			width = 0;
			height = 0;
			depth = 0;
			target = -1;

			int i;

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
					index = input.resource_index
				};

				_texture_buffer += tex_unit;
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
				if(!(input.resource_index < ShadertoyResourceManager.TEXTURE_IDS.length))
				{
					input.resource_index = 0;
				}

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
				if(!(input.resource_index < ShadertoyResourceManager.3DTEXTURE_IDS.length))
				{
					input.resource_index = 0;
				}

				target = GL_TEXTURE_3D;
				tex_ids = {0};
				glGenTextures(1,tex_ids);
				glBindTexture(target, tex_ids[0]);

				ShadertoyResourceManager.Voxmap voxmap = ShadertoyResourceManager.3DTEXTURE_VOXMAPS[input.resource_index];

				width = voxmap.width;
				height = voxmap.height;
				depth = voxmap.depth;

				int format=-1;
				if (voxmap.n_channels == 1)
				{
					format = GL_RED;
				}
				else if (voxmap.n_channels == 3)
				{
					format = GL_RGB;
				}
				else if (voxmap.n_channels == 4)
				{
					format = GL_RGBA;
				}

				glTexImage3D(GL_TEXTURE_3D, 0, GL_RGBA, width, height, depth, 0, format, GL_UNSIGNED_BYTE, (GLvoid[])voxmap.voxels);
				glGenerateMipmap(target);
			}
			else if(input.type == Shader.InputType.CUBEMAP)
			{
				if(!(input.resource_index < ShadertoyResourceManager.CUBEMAP_IDS.length))
				{
					input.resource_index = 0;
				}

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
			else
			{
				target = GL_TEXTURE_2D;
				tex_ids = {0};
				glGenTextures(1,tex_ids);

				width = _width;
				height = _height;

				glBindTexture(target, tex_ids[0]);
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});
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

			time = (_curr_time - _start_time) / 1000000.0f;
			_delta = _delta_time / 1000000.0f;

			_curr_date = new DateTime.now_local();

			_curr_date.get_ymd(out _year, out _month, out _day);

			_seconds = (float)((_curr_date.get_hour()*60+_curr_date.get_minute())*60)+(float)_curr_date.get_seconds();
		}

		private int64 render_gl(BufferProperties buf_prop)
		{
			buf_prop.context.make_current();

			if(buf_prop.fb!=0){
				glBindFramebuffer(GL_DRAW_FRAMEBUFFER, buf_prop.fb);
				glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, buf_prop.tex_id_out_back, 0);
			}

			glViewport(0, 0, _width, _height);

			int64 time_after = 0, time_before = 0;

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

			glBindVertexArray(buf_prop.vao);

			glFinish();

			time_before = get_monotonic_time();

			glDrawArrays(GL_TRIANGLES, 0, 3);

			glFlush();
			glFinish();

			time_after = get_monotonic_time();

			glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
			glFinish();

			return time_after - time_before;
		}
	}
}
