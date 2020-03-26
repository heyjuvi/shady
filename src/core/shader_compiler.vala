using GL;

namespace Shady.Core
{
	public class ShaderCompiler
	{
		public ShaderCompiler()
		{
		}

		private const string _channel_string = "iChannel";
		private const uint _default_tile_size = 64;
		private const int64 _default_time_delta = 100000;

		private class ThreadData
		{
			public Shader shader;
			public Gdk.GLContext context;
			public RenderResources render_resources;
			public CompileResources compile_resources;
		}

		private static ThreadPool<ThreadData> _compile_pool;

		public static void initialize_pool()
		{
			if (_compile_pool == null)
			{
				try{
					_compile_pool = new ThreadPool<ThreadData>.with_owned_data((data) =>
					{
						compile(data);
					}, (int) GLib.get_num_processors() - 1, false);
				}
				catch(Error e){
					print("Could not initialize ThreadPool\n");
				}
			}
		}

		public static void queue_shader_compile(Shader shader, RenderResources render_resources, CompileResources compile_resources)
		{
			if (compile_resources.mutex.trylock())
			{
				Gdk.GLContext thread_context;

				try
				{
					thread_context = compile_resources.window.create_gl_context();
					thread_context.realize();
				}
				catch(Error e)
				{
					print("Couldn't create gl context\n");
					return;
				}

				RenderResources.BufferProperties[] buf_props = allocate_buffers(shader);

				for(int i=0;i<buf_props.length;i++)
				{
					buf_props[i].context = thread_context;
				}

				render_resources.set_buffer_props(RenderResources.Purpose.COMPILE, buf_props);
				render_resources.set_image_prop_index(RenderResources.Purpose.COMPILE, 0);

				ThreadData data = new ThreadData(){shader=shader, context = thread_context, render_resources=render_resources, compile_resources=compile_resources};

				try
				{
					_compile_pool.add(data);
				}
				catch(Error e)
				{
					print("Couldn't queue compile\n");
				}
			}
		}

		public static void compile_main_thread(Shader shader, RenderResources render_resources, CompileResources compile_resources)
		{
			compile_resources.mutex.lock();
			RenderResources.BufferProperties[] buf_props = allocate_buffers(shader);

			Gdk.GLContext current_context = Gdk.GLContext.get_current();

			for(int i=0;i<buf_props.length;i++)
			{
				buf_props[i].context = current_context;
			}

			render_resources.set_buffer_props(RenderResources.Purpose.COMPILE, buf_props);
			render_resources.set_image_prop_index(RenderResources.Purpose.COMPILE, 0);

			ThreadData data = new ThreadData(){shader=shader, context = current_context, render_resources=render_resources, compile_resources=compile_resources};

			compile(data);
		}

		private static void compile(ThreadData data)
		{
			data.context.make_current();

			bool success = compile_blocking(data.shader, data.render_resources, data.compile_resources);
			if (success)
			{
				RenderResources.BufferProperties[] buf_props = data.render_resources.get_buffer_props(RenderResources.Purpose.COMPILE);
				foreach (RenderResources.BufferProperties buf_prop in buf_props)
				{
					dummy_render_gl(buf_prop);
				}
			}

			Gdk.GLContext.clear_current();

			data.render_resources.switch_buffer();

			data.compile_resources.mutex.unlock();

			Timeout.add(1,() =>
			{
				data.compile_resources.compilation_finished();
				return false;
			});
		}

		private static bool compile_blocking(Shader new_shader, RenderResources render_resources, CompileResources compile_resources)
		{
			RenderResources.BufferProperties[] buffer_props = render_resources.get_buffer_props(RenderResources.Purpose.COMPILE);

			int buffer_count = buffer_props.length;

			string[] buffer_sources = new string[buffer_count];
			int[] buffer_indices = new int[buffer_count];
			Array<Shader.Input>[] buffer_inputs = new Array<Shader.Input>[buffer_count];
			Shader.Output[] buffer_outputs = new Shader.Output[buffer_count];

			if(buffer_count>0)
			{
				GLuint[] fbs = new GLuint[buffer_count];
				glGenFramebuffers(buffer_count, fbs);

				int buffer_index=0;
				for(int i=0; i<new_shader.renderpasses.length;i++)
				{
					if(new_shader.renderpasses.index(i).type == Shader.RenderpassType.BUFFER ||
					   new_shader.renderpasses.index(i).type == Shader.RenderpassType.IMAGE)
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
					buffer_props[i].fb = fbs[i];

					GLuint[] output_tex_ids = TextureManager.query_output_texture(buffer_outputs[i], (uint64) compile_resources.window, compile_resources.width, compile_resources.height);
					buffer_props[i].tex_id_out_front = output_tex_ids[0];
					buffer_props[i].tex_id_out_back = output_tex_ids[1];

					if(buffer_outputs[i] == null)
					{
						render_resources.set_image_prop_index(RenderResources.Purpose.COMPILE, i);
					}

					glClearColor(0,0,0,1);
					glClear(GL_COLOR_BUFFER_BIT);

					glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);

					int num_samplers = (int)buffer_inputs[i].length;

					buffer_props[i].sampler_ids = new GLuint[num_samplers];
					glGenSamplers(num_samplers, buffer_props[i].sampler_ids);

					buffer_props[i].tex_widths = {0,0,0,0};
					buffer_props[i].tex_heights = {0,0,0,0};
					buffer_props[i].tex_depths = {0,0,0,0};

					buffer_props[i].cur_x_img_part = 0;
					buffer_props[i].cur_y_img_part = 0;

					buffer_props[i].x_img_parts = compile_resources.width/_default_tile_size;
					buffer_props[i].y_img_parts = compile_resources.height/_default_tile_size;

					buffer_props[i].time_delta = _default_time_delta;
					buffer_props[i].tile_time_max = -double.INFINITY;
					buffer_props[i].tile_time_sum = 0.0;

					buffer_props[i].parts_rendered = false;
					buffer_props[i].second_resize = false;
					buffer_props[i].updated = true;

					buffer_props[i].frame_counter = 0;

					if(compile_resources.width==0)
					{
						buffer_props[i].x_img_parts = 8;
					}
					if(compile_resources.height==0)
					{
						buffer_props[i].y_img_parts = 8;
					}

					init_tile_renderbuffer(buffer_props[i], compile_resources);

					buffer_props[i].tex_channels = new int[num_samplers];
					buffer_props[i].tex_ids = new uint[num_samplers];
					buffer_props[i].tex_targets = new uint[num_samplers];

					for(int j=0;j<num_samplers;j++)
					{
						int width, height, depth, channel;

						init_sampler(buffer_inputs[i].index(j), buffer_props[i].sampler_ids[j]);

						width = compile_resources.width;
						height = compile_resources.height;
						depth = 0;

						GLuint tex_target;
						GLuint[] tex_ids = TextureManager.query_input_texture(buffer_inputs[i].index(j), (uint64) compile_resources.window, ref width, ref height, ref depth, out tex_target);
						buffer_props[i].tex_targets[j] = tex_target;
						buffer_props[i].tex_ids[j] = tex_ids[0];

						channel = buffer_inputs[i].index(j).channel;
						buffer_props[i].tex_channels[j] = channel;

						if(channel>=0 && channel<4){
							buffer_props[i].tex_widths[channel] = width;
							buffer_props[i].tex_heights[channel] = height;
							buffer_props[i].tex_depths[channel] = depth;
						}
					}
				}

				for(int i=0;i<buffer_count;i++)
				{
					int num_refs = 0;
					for(int j=0;j<buffer_count;j++)
					{
						for(int k=0;k<buffer_props[j].tex_ids.length;k++)
						{
							if(buffer_props[j].tex_ids[k] == buffer_props[i].tex_id_out_front)
							{
								num_refs++;
							}
						}
					}

					buffer_props[i].tex_out_refs = new int[num_refs,2];
					int ref_index=0;
					for(int j=0;j<buffer_count;j++)
					{
						for(int k=0;k<buffer_props[j].tex_ids.length;k++)
						{
							if(buffer_props[j].tex_ids[k] == buffer_props[i].tex_id_out_front)
							{
								buffer_props[i].tex_out_refs[ref_index,0] = j;
								buffer_props[i].tex_out_refs[ref_index,1] = k;
								ref_index++;
							}
						}
					}
				}
			}

			Shader.Renderpass common_pass = new_shader.get_renderpass_by_name("Common");
			string common_code = "";

			if(common_pass != null)
			{
				common_code = common_pass.code;
			}

			for(int i=0;i<buffer_count;i++)
			{
				Shader.Renderpass buffer_pass = new_shader.renderpasses.index(buffer_indices[i]);
				string full_buffer_source = SourceGenerator.generate_renderpass_source(buffer_pass, true, common_code);

				bool success = compile_pass(buffer_indices[i], full_buffer_source, buffer_props[i], compile_resources);

				if (!success)
				{
					return false;
				}
			}

            return true;
		}

		public static bool compile_pass(int pass_index, string shader_source, RenderResources.BufferProperties buf_prop, CompileResources compile_resources)
		{
			string[] source_array = { shader_source, null };

			glShaderSource(compile_resources.fragment_shader, 1, source_array, null);
			glCompileShader(compile_resources.fragment_shader);

			GLint success[] = {0};
			glGetShaderiv(compile_resources.fragment_shader, GL_COMPILE_STATUS, success);

			if (success[0] == GL_FALSE)
			{
				print("Compile error:\n");
				GLint log_size[] = {0};
				glGetShaderiv(compile_resources.fragment_shader, GL_INFO_LOG_LENGTH, log_size);
				GLubyte[] log = new GLubyte[log_size[0]];
				glGetShaderInfoLog(compile_resources.fragment_shader, log_size[0], log_size, log);

				if (log.length > 0)
				{
					foreach (GLubyte c in log)
					{
						print(@"$((char)c)");
					}

					Timeout.add(1,() =>
					{
						compile_resources.pass_compilation_terminated(pass_index, new ShaderError.COMPILATION((string) log));
						return false;
					});
				}
				else
				{
					Timeout.add(1,() =>
					{
						compile_resources.pass_compilation_terminated(pass_index, new ShaderError.COMPILATION("Something went substantially wrong..."));
						return false;
					});
				}

				return false;
			}

			glDeleteProgram(buf_prop.program);
			buf_prop.program = glCreateProgram();

			glAttachShader(buf_prop.program, compile_resources.vertex_shader);
			glAttachShader(buf_prop.program, compile_resources.fragment_shader);

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
				buf_prop.channel_locs[i] = glGetUniformLocation(buf_prop.program, _channel_string+@"$(buf_prop.tex_channels[i])");
			}

			buf_prop.date_loc = glGetUniformLocation(buf_prop.program, "iDate");
			buf_prop.samplerate_loc = glGetUniformLocation(buf_prop.program, "iSampleRate");
			buf_prop.offset_loc = glGetUniformLocation(buf_prop.program, "SHADY_COORDINATE_OFFSET");

			init_vao(buf_prop);

			bind_vertex_buffer(buf_prop, compile_resources);

			Timeout.add(1,() =>
			{
				compile_resources.pass_compilation_terminated(pass_index, null);
				return false;
			});

			return true;
		}

		private static RenderResources.BufferProperties[] allocate_buffers(Shader shader)
		{
			int buffer_count = 0;
			for(int i=0; i<shader.renderpasses.length; i++)
			{
				if(shader.renderpasses.index(i).type == Shader.RenderpassType.BUFFER ||
				   shader.renderpasses.index(i).type == Shader.RenderpassType.IMAGE)
				{
					buffer_count++;
				}
			}
			RenderResources.BufferProperties[] buffer_props = new RenderResources.BufferProperties[buffer_count];
			for(int i=0; i<buffer_count; i++)
			{
				buffer_props[i] = new RenderResources.BufferProperties();
			}
			return buffer_props;
		}

		public static void init_compile_resources(CompileResources compile_resources)
		{
			compile_vertex_shader(compile_resources);
			init_vbo(compile_resources);

			compile_resources.fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);
		}

		public static void compile_vertex_shader(CompileResources compile_resources)
		{
			string vertex_source = SourceGenerator.generate_vertex_source(true);
			string[] vertex_source_array = { vertex_source, null };

			compile_resources.vertex_shader = glCreateShader(GL_VERTEX_SHADER);
			glShaderSource(compile_resources.vertex_shader, 1, vertex_source_array, null);
			glCompileShader(compile_resources.vertex_shader);
		}

		public static void init_vao(RenderResources.BufferProperties buf_prop)
		{
			GLuint[] vao_arr = {buf_prop.vao};

			glDeleteVertexArrays(1, vao_arr);
			glGenVertexArrays(1, vao_arr);
			buf_prop.vao = vao_arr[0];
		}

		public static void init_vbo(CompileResources compile_resources)
		{
			GLuint[] vbo = {0};
			glGenBuffers(1, vbo);

			compile_resources.vbo=vbo[0];

			GLfloat[] vertices = { -1, -1,
								    3, -1,
								   -1,  3 };

			glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
			glBufferData(GL_ARRAY_BUFFER, vertices.length * sizeof (GLfloat), (GLvoid[]) vertices, GL_STATIC_DRAW);

			glBindBuffer(GL_ARRAY_BUFFER, 0);
		}

		public static void bind_vertex_buffer(RenderResources.BufferProperties buf_prop, CompileResources compile_resources)
		{
			glBindVertexArray(buf_prop.vao);
			glBindBuffer(GL_ARRAY_BUFFER, compile_resources.vbo);

			GLuint attrib0 = glGetAttribLocation(buf_prop.program, "v");

			glEnableVertexAttribArray(attrib0);
			glVertexAttribPointer(attrib0, 2, GL_FLOAT, (GLboolean) GL_FALSE, 0, null);

			glBindBuffer(GL_ARRAY_BUFFER, 0);
			glBindVertexArray(0);
		}

		private static void init_tile_renderbuffer(RenderResources.BufferProperties buf_prop, CompileResources compile_resources)
		{
			GLuint[] rb_arr = {0};
			glGenRenderbuffers(1, rb_arr);
			buf_prop.tile_render_buf = rb_arr[0];

			glBindRenderbuffer(GL_RENDERBUFFER, buf_prop.tile_render_buf);
			glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA32F, (int)compile_resources.width, (int)compile_resources.height);
		}

		public static void init_sampler(Shader.Input input, GLuint sampler_id)
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
				glSamplerParameteri(sampler_id, GL_TEXTURE_WRAP_R, GL_REPEAT);
			}
			else if(input.sampler.wrap == Shader.WrapMode.CLAMP)
			{
				glSamplerParameteri(sampler_id, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
				glSamplerParameteri(sampler_id, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
				glSamplerParameteri(sampler_id, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
			}
		}

		private static void dummy_render_gl(RenderResources.BufferProperties buf_prop)
		{
			glViewport(0, 0, 256, 256);

			glUseProgram(buf_prop.program);

			glBindVertexArray(buf_prop.vao);

			glDrawArrays(GL_TRIANGLES, 0, 3);

			glFlush();
			glFinish();
		}

		public static List<AppPreferences.GLSLVersion> get_glsl_version_list(Gdk.Window window)
		{
			Gdk.GLContext gl_context;

			try
			{
				gl_context = window.create_gl_context();
				gl_context.make_current();
			}
			catch(Error e)
			{
				print("Couldn't create context\n");
				return new List<AppPreferences.GLSLVersion>();
			}

			GLuint fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);

			List<AppPreferences.GLSLVersion> version_list = new List<AppPreferences.GLSLVersion>();

			for(AppPreferences.GLSLVersion version=0;version<AppPreferences.GLSLVersion.INVALID;version+=1)
			{
				string source = version.to_prefix_string() + "void main(void){}\n";
				string[] source_array = { source, null };

				glShaderSource(fragment_shader, 1, source_array, null);
				glCompileShader(fragment_shader);

				GLint success[] = {0};

				glGetShaderiv(fragment_shader, GL_COMPILE_STATUS, success);

				if(success[0] == GL_TRUE)
				{
					version_list.append(version);
				}
			}

			glDeleteShader(fragment_shader);

			Gdk.GLContext.clear_current();

			return version_list;
		}
	}
}
