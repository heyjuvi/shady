using GL;
using Gtk;
using Gdk;
using Shady.Core;

namespace Shady
{
	public class ShaderArea : GLArea
	{
		public signal void initialized();

		public double fps { get; protected set; }
		public double time { get; protected set; }

		/* Properties */
		public double time_slider { get; set; default = 0.0; }

		protected bool _paused = false;
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

		/* Constants */
		private const double _time_slider_factor = 2.0;

		/* Time variables */
		protected DateTime _curr_date;

		protected int64 _start_time;
		protected int64 _curr_time;
		protected int64 _pause_time;
		protected int64 _delta_time;

		protected float _year;
		protected float _month;
		protected float _day;
		protected float _seconds;

		protected float _delta;

		protected float _samplerate = 44100.0f;

		/* Initialized */
		protected bool _initialized = false;
		protected bool _size_updated = false;

		/* Mouse variables */
		protected bool _button_pressed;
		protected double _button_pressed_x;
		protected double _button_pressed_y;
		protected double _button_released_x;
		protected double _button_released_y;

		protected double _mouse_x = 0;
		protected double _mouse_y = 0;

		/* Shader render buffer variables */

		protected int _width = 0;
		protected int _height = 0;

		private Mutex _size_mutex = Mutex();

		public ShaderArea()
		{
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
		}

		public static Shader? get_default_shader()
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

		protected void update_uniform_values()
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

		protected void set_uniform_values(RenderResources.BufferProperties buf_prop)
		{
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
		}

		protected void init_vertex_buffers(RenderResources.BufferProperties buf_prop)
		{
			GLuint[] vao_arr = {0};

			glGenVertexArrays(1, vao_arr);
			glBindVertexArray(vao_arr[0]);
			buf_prop.vao = vao_arr[0];

			GLuint[] vbo = {0};
			glGenBuffers(1, vbo);

			GLfloat[] vertices = { -1, -1,
								    3, -1,
								   -1,  3 };

			glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
			glBufferData(GL_ARRAY_BUFFER, vertices.length * sizeof (GLfloat), (GLvoid[]) vertices, GL_STATIC_DRAW);

			GLuint attrib0 = glGetAttribLocation(buf_prop.program, "v");

			glEnableVertexAttribArray(attrib0);
			glVertexAttribPointer(attrib0, 2, GL_FLOAT, (GLboolean) GL_FALSE, 0, null);

			glBindBuffer(GL_ARRAY_BUFFER, 0);
			glBindVertexArray(0);
		}

		protected void init_target_pass(RenderResources.BufferProperties buf_prop, CompileResources comp_resources, GLuint tex_id)
		{
			buf_prop.sampler_ids = new GLuint[1];
			glGenSamplers(1, buf_prop.sampler_ids);
			Shader.Input target_input = new Shader.Input();
			target_input.sampler = new Shader.Sampler();
			target_input.sampler.filter = Shader.FilterMode.LINEAR;
			target_input.sampler.wrap = Shader.WrapMode.REPEAT;
			ShaderCompiler.init_sampler(target_input, buf_prop.sampler_ids[0]);
			buf_prop.tex_widths = new int[4];
			buf_prop.tex_heights = new int[4];
			buf_prop.tex_depths = new int[4];
			buf_prop.tex_channels = {0};
			buf_prop.tex_widths = {0,0,0,0};
			buf_prop.tex_heights = {0,0,0,0};
			buf_prop.tex_depths = {0,0,0,0};
			buf_prop.tex_targets = {GL_TEXTURE_2D};
			buf_prop.fb = 0;
			buf_prop.tex_ids = {tex_id};

			string target_vertex_source = SourceGenerator.generate_vertex_source(false);
			string[] target_vertex_source_array = { target_vertex_source, null };

			GLuint target_vertex_shader = glCreateShader(GL_VERTEX_SHADER);
			glShaderSource(target_vertex_shader, 1, target_vertex_source_array, null);
			glCompileShader(target_vertex_shader);

			comp_resources.vertex_shader = target_vertex_shader;

			buf_prop.program = glCreateProgram();
			buf_prop.context = get_context();

			comp_resources.fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);

			glAttachShader(buf_prop.program, comp_resources.vertex_shader);
			glAttachShader(buf_prop.program, comp_resources.fragment_shader);

			Shader.Input input = new Shader.Input();
			input.type = Shader.InputType.TEXTURE;
			input.channel = 0;
			Shader.Renderpass target_pass = ChannelArea.get_renderpass_from_input(input);

			string full_target_source = SourceGenerator.generate_renderpass_source(target_pass, false);

			ShaderCompiler.compile_pass(-1, full_target_source, buf_prop, comp_resources);
		}

		public void reset_time()
		{
			_start_time = _curr_time;
			_pause_time = _curr_time;
		}

		protected void init_time()
		{
			_start_time = get_monotonic_time();
		}
	}
}
