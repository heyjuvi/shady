using GL;
using Gtk;
using Gdk;
using Shady.Core;

namespace Shady
{
	public class ChannelArea : ShaderArea
	{
		/* Buffer properties structs*/
		private RenderResources.BufferProperties _target_prop = new RenderResources.BufferProperties();
		private CompileResources _compile_resources = new CompileResources();

		/* OpenGL ids */
		private const string _channel_string = "iChannel";

		/* Time variables */
		private DateTime _curr_date;

		private int64 _start_time;
		private int64 _curr_time;
		private int64 _delta_time;

		/* Shader render buffer variables */

		private Mutex _size_mutex = Mutex();

		public ChannelArea()
		{
			realize.connect(() =>
			{
				init_gl(get_default_shader());
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
		}

		public static Shader? get_shader_from_input(Shader.Input input)
		{
			Shader.Renderpass input_renderpass = get_renderpass_from_input(input);

			Shader input_shader = new Shader();
			input_shader.renderpasses.append_val(input_renderpass);

			return input_shader;
		}

		public static Shader.Renderpass? get_renderpass_from_input(Shader.Input input)
		{
			Shader.Renderpass input_renderpass = new Shader.Renderpass();
			input_renderpass.inputs.append_val(input);
			input_renderpass.type = Shader.RenderpassType.IMAGE;

			/*
			if (input.resource == null)
			{
				print("Input has no specified resource!\n");
				return null;
			}
			*/

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

			return input_renderpass;
		}

		public void compile_shader_input(Shader.Input input)
		{
			if(input.resource!=null){
				_target_prop.context.make_current();
				int width, height, depth, channel;
				GLuint tex_target;

				ShaderCompiler.init_sampler(input, _target_prop.sampler_ids[0]);

				GLuint[] tex_ids = TextureManager.query_input_texture(input, (uint64) get_window(), out width, out height, out depth, out tex_target);

				if(tex_ids != null && tex_ids.length > 0){

					Shader? input_shader = get_shader_from_input(input);

					string target_source = input_shader.renderpasses.index(0).code;

					string full_target_source = SourceGenerator.generate_renderpass_source(input_shader.renderpasses.index(0));

					ShaderCompiler.compile_pass(-1, full_target_source, _target_prop, _compile_resources);

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

		private void init_gl(Shader default_shader)
		{
			make_current();

			string vertex_source = SourceGenerator.generate_vertex_source();
			string[] vertex_source_array = { vertex_source, null };

			_compile_resources.vertex_shader = glCreateShader(GL_VERTEX_SHADER);
			glShaderSource(_compile_resources.vertex_shader, 1, vertex_source_array, null);
			glCompileShader(_compile_resources.vertex_shader);

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
			ShaderCompiler.init_sampler(target_input, _target_prop.sampler_ids[0]);
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

			_compile_resources.fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);

			glAttachShader(_target_prop.program, _compile_resources.vertex_shader);
			glAttachShader(_target_prop.program, _compile_resources.fragment_shader);

			Shader.Input input = new Shader.Input();
			input.type = Shader.InputType.TEXTURE;
			input.channel = 0;
			Shader.Renderpass target_pass = get_renderpass_from_input(input);

			string full_target_source = SourceGenerator.generate_renderpass_source(target_pass);

			ShaderCompiler.compile_pass(-1, full_target_source, _target_prop, _compile_resources);

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

		private int64 render_gl(RenderResources.BufferProperties buf_prop)
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
