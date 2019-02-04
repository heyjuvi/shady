using GL;
using Gtk;
using Gdk;
using Shady.Core;

namespace Shady
{
	public errordomain ShaderError
	{
		COMPILATION
	}

	public class ShadertoyArea : ShaderArea
	{
		public signal void compilation_finished();
		public signal void pass_compilation_terminated(int pass_index, ShaderError? e);

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

		public double time_slider { get; set; default = 0.0; }

		private GLuint _tile_render_buf;
		private uint _render_timeout;

		private GLib.Settings _settings = new GLib.Settings("org.hasi.shady");

		/* Buffer properties structs*/
		private RenderResources.BufferProperties _target_prop = new RenderResources.BufferProperties();

		private RenderResources _render_resources = new RenderResources();
		private CompileResources _compile_resources = new CompileResources();

		/* Constants */
		private const double _time_slider_factor = 2.0;
		private int _x_image_parts = 4;
		private int _y_image_parts = 4;

		private bool _adaptive_tiling = true;

		/* OpenGL ids */

		private GLuint _resize_fb;

		/* Time variables */
		private DateTime _curr_date;

		private int64 _start_time;
		private int64 _curr_time;
		private int64 _pause_time;
		private int64 _delta_time;

		/* Shader render buffer variables */

		private int64 _time_delta_accum = 0;

		private Mutex _compile_mutex = Mutex();
		private Cond _compile_cond = Cond();

		private Mutex _size_mutex = Mutex();

		public ShadertoyArea()
		{
			realize.connect(() =>
			{
				_settings.get_value("num-tilings").get("(ii)", out _x_image_parts, out _y_image_parts);
				_adaptive_tiling = _settings.get_boolean("adaptive-tiling");

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

			render.connect(() =>
			{
				_size_mutex.lock();
				render_gl(_target_prop);
				_size_mutex.unlock();
				queue_draw();
				return false;
			});

			unrealize.connect(() =>
			{
				Source.remove(_render_timeout);

				//_compile_mutex.lock();
				//_compile_cond.wait(_compile_mutex);
				//_compile_mutex.unlock();
			});

			_compile_resources.compilation_finished.connect(() =>
			{
				compilation_finished();
			});

			_compile_resources.pass_compilation_terminated.connect((pass_index, e) =>
			{
				pass_compilation_terminated(pass_index,e);
			});
		}

		public void compile(Shader shader)
		{
			ShaderCompiler.queue_shader_compile(shader, _render_resources, _compile_resources);
		}

		public static Shader? get_loading_shader()
		{
			Shader loading_shader = new Shader();
			Shader.Renderpass renderpass = new Shader.Renderpass();

			try
			{
				string loading_code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/load.glsl", 0).get_data());
				renderpass.code = loading_code;
			}
			catch(Error e)
			{
				print("Couldn't load loading shader!\n");
				return null;
			}

			renderpass.type = Shader.RenderpassType.IMAGE;
			renderpass.name = "Image";

			loading_shader.renderpasses.append_val(renderpass);

			return loading_shader;
		}

		public void reset_time()
		{
			_start_time = _curr_time;
			_pause_time = _curr_time;
		}

		private void init_gl(Shader default_shader)
		{
			make_current();

			ShaderCompiler.initialize_pool();
			_compile_resources.window = get_window();

			string vertex_source = SourceGenerator.generate_vertex_source(true);
			string[] vertex_source_array = { vertex_source, null };

			_compile_resources.vertex_shader = glCreateShader(GL_VERTEX_SHADER);
			glShaderSource(_compile_resources.vertex_shader, 1, vertex_source_array, null);
			glCompileShader(_compile_resources.vertex_shader);

			GLuint[] tex_arr = {0};
			glGenTextures(1, tex_arr);

			RenderResources.BufferProperties image_prop1 = _render_resources.get_image_prop(RenderResources.Purpose.RENDER);
			RenderResources.BufferProperties image_prop2 = _render_resources.get_image_prop(RenderResources.Purpose.COMPILE);

			image_prop1.tex_id_out_back = tex_arr[0];
			image_prop2.tex_id_out_back = tex_arr[0];

			glBindTexture(GL_TEXTURE_2D, tex_arr[0]);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});

			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);

			glGenTextures(1, tex_arr);
			image_prop1.tex_id_out_front = tex_arr[0];
			image_prop2.tex_id_out_front = tex_arr[0];

			glBindTexture(GL_TEXTURE_2D, tex_arr[0]);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});

			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);

			GLuint[] rb_arr = {0};
    		glGenRenderbuffers(1,rb_arr);
			_tile_render_buf=rb_arr[0];

    		glBindRenderbuffer(GL_RENDERBUFFER,_tile_render_buf);

			int width=_width/_x_image_parts;
			int height=_height/_x_image_parts;

			if(width<_width-(_x_image_parts-1)*(int)(width)){
				width=_width-(_x_image_parts-1)*(int)(width);
			}
			if(height<_height-(_y_image_parts-1)*(int)(height)){
				height=_height-(_y_image_parts-1)*(int)(height);
			}

    		glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA, width, height);

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
			_target_prop.tex_ids = {image_prop1.tex_id_out_front};
			_target_prop.tex_targets = {GL_TEXTURE_2D};
			_target_prop.fb = 0;

			Shader.Input input = new Shader.Input();
			input.type = Shader.InputType.TEXTURE;
			input.channel = 0;
			Shader.Renderpass target_pass = ChannelArea.get_renderpass_from_input(input);

			string target_vertex_source = SourceGenerator.generate_vertex_source(false);
			string[] target_vertex_source_array = { target_vertex_source, null };

			GLuint target_vertex_shader = glCreateShader(GL_VERTEX_SHADER);
			glShaderSource(target_vertex_shader, 1, target_vertex_source_array, null);
			glCompileShader(target_vertex_shader);

			GLuint vertex_shader_backup = _compile_resources.vertex_shader;
			_compile_resources.vertex_shader = target_vertex_shader;

			_target_prop.program = glCreateProgram();
			_target_prop.context = get_context();

			_compile_resources.fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);

			glAttachShader(_target_prop.program, _compile_resources.vertex_shader);
			glAttachShader(_target_prop.program, _compile_resources.fragment_shader);

			string full_target_source = SourceGenerator.generate_renderpass_source(target_pass, false);

			ShaderCompiler.compile_pass(-1, full_target_source, _target_prop, _compile_resources);

			_compile_resources.vertex_shader = vertex_shader_backup;

			image_prop1.program = glCreateProgram();
			image_prop2.program = glCreateProgram();

			glAttachShader(image_prop1.program, _compile_resources.vertex_shader);
			glAttachShader(image_prop1.program, _compile_resources.fragment_shader);

			glAttachShader(image_prop2.program, _compile_resources.vertex_shader);
			glAttachShader(image_prop2.program, _compile_resources.fragment_shader);

			compile(default_shader);

			//_compile_mutex.lock();
			//_compile_cond.wait(_compile_mutex);
			//_compile_mutex.unlock();

			compile(default_shader);

			//_compile_mutex.lock();
			//_compile_cond.wait(_compile_mutex);
			//_compile_mutex.unlock();

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

			//glBindBuffer(GL_ARRAY_BUFFER, 0);
			//glBindVertexArray(0);

			GLuint[] fb_arr = {0};

			glGenFramebuffers(1, fb_arr);
			_resize_fb = fb_arr[0];

			//_render_context1.make_current();
			//image_prop1.context = _render_context1;
			image_prop1.context = get_context();

			glGenFramebuffers(1, fb_arr);
			image_prop1.fb = fb_arr[0];

			//glGenVertexArrays(1, vao_arr);
			//glBindVertexArray(vao_arr[0]);
			image_prop1.vao = vao_arr[0];

			//glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);

			GLuint attrib1 = glGetAttribLocation(image_prop1.program, "v");

			glEnableVertexAttribArray(attrib1);
			glVertexAttribPointer(attrib1, 2, GL_FLOAT, (GLboolean) GL_FALSE, 0, null);

			//glBindBuffer(GL_ARRAY_BUFFER, 0);

			//_render_context2.make_current();
			image_prop2.context = get_context();

			glGenFramebuffers(1, fb_arr);
			image_prop2.fb = fb_arr[0];

			//glGenVertexArrays(1, vao_arr);
			//glBindVertexArray(vao_arr[0]);
			image_prop2.vao = vao_arr[0];

			//glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);

			GLuint attrib2 = glGetAttribLocation(image_prop2.program, "v");

			glEnableVertexAttribArray(attrib2);
			glVertexAttribPointer(attrib2, 2, GL_FLOAT, (GLboolean) GL_FALSE, 0, null);

			glBindBuffer(GL_ARRAY_BUFFER, 0);
			glBindVertexArray(0);

			_start_time = get_monotonic_time();

			Gdk.GLContext.clear_current();

			_render_timeout = Timeout.add(1,render_image);

			add_events(EventMask.BUTTON_PRESS_MASK |
					   EventMask.BUTTON_RELEASE_MASK |
					   EventMask.POINTER_MOTION_MASK);
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

		private bool render_image()
		{
			_render_resources.buffer_switch_mutex.lock();

			RenderResources.BufferProperties img_prop = _render_resources.get_image_prop(RenderResources.Purpose.RENDER);
			RenderResources.BufferProperties[] buf_props = _render_resources.get_buffer_props(RenderResources.Purpose.RENDER);

			if (_initialized)
			{
				_size_mutex.lock();

				if(_size_updated)
				{
					make_current();

    				glBindRenderbuffer(GL_RENDERBUFFER,_tile_render_buf);

					int width=_width/_x_image_parts;
					int height=_height/_x_image_parts;

					if(width<_width-(_x_image_parts-1)*(int)(width)){
						width=_width-(_x_image_parts-1)*(int)(width);
					}
					if(height<_height-(_y_image_parts-1)*(int)(height)){
						height=_height-(_y_image_parts-1)*(int)(height);
					}

					glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA, width, height);

					img_prop.cur_x_img_part = 0;
					img_prop.cur_y_img_part = 0;

					for(int i=0; i<buf_props.length; i++)
					{
						buf_props[i].cur_x_img_part = 0;
						buf_props[i].cur_y_img_part = 0;
					}

					glBindTexture(GL_TEXTURE_2D, img_prop.tex_id_out_back);
					glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});

					glBindFramebuffer(GL_DRAW_FRAMEBUFFER, _resize_fb);
					glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, img_prop.tex_id_out_back, 0);

					//TODO: fix multipass again, include in texture manager somehow?
					/*
					for(int i=0;i<_buffer_buffer.length;i++)
					{
						_buffer_buffer[i].width=_width;
						_buffer_buffer[i].height=_height;
						
						for(int j=0;j<2;j++)
						{
							glBindTexture(GL_TEXTURE_2D, _buffer_buffer[i].tex_ids[j]);
							glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});

							glBindFramebuffer(GL_DRAW_FRAMEBUFFER, _resize_fb);
							glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _buffer_buffer[i].tex_ids[j], 0);

							glClearColor(0,0,0,1);
							glClear(GL_COLOR_BUFFER_BIT);
						}
					}
					*/

					_size_updated = false;
				}

				if(img_prop.cur_x_img_part == 0 && img_prop.cur_y_img_part == 0)
				{
					update_uniform_values();
				}

				for(int i=0; i<buf_props.length; i++)
				{
					render_gl(buf_props[i]);
				}

				for(int i=0; i<buf_props.length; i++)
				{
					if(buf_props[i].cur_x_img_part == 0 && buf_props[i].cur_y_img_part == 0)
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
							img_prop.tex_ids[buf_props[i].tex_out_refs_img.index(j)] = tmp;
						}
					}
				}

				int64 time_delta = render_gl(img_prop);
				_time_delta_accum += time_delta;

				if(img_prop.cur_x_img_part == 0 && img_prop.cur_y_img_part == 0)
				{
					uint tmp = img_prop.tex_id_out_back;
					img_prop.tex_id_out_back = img_prop.tex_id_out_front;
					img_prop.tex_id_out_front = tmp;

					_target_prop.tex_ids[0] = tmp;

					glBindTexture(GL_TEXTURE_2D, img_prop.tex_id_out_back);

					int width[] = {0};
					int height[] = {0};

					glGetTexLevelParameteriv(GL_TEXTURE_2D,0,GL_TEXTURE_WIDTH,width);
					glGetTexLevelParameteriv(GL_TEXTURE_2D,0,GL_TEXTURE_HEIGHT,height);

					if(width[0] != _width || height[0] != _height)
					{
						glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});
					}

					// compute moving average
					if (fps != 0)
					{
						fps = (0.95 * fps + 0.05 * (1000000.0f / _time_delta_accum));
					}
					else
					{
						fps = 1000000.0f / _time_delta_accum;
					}

					_time_delta_accum = 0;
				}

				_size_mutex.unlock();
			}
			_render_resources.buffer_switch_mutex.unlock();

			return true;
		}

		private int64 render_gl(RenderResources.BufferProperties buf_prop)
		{
			make_current();

			if(buf_prop.fb!=0)
			{
				glBindFramebuffer(GL_DRAW_FRAMEBUFFER, buf_prop.fb);
    			glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _tile_render_buf);
			}

			int cur_width=_width/_x_image_parts;
			int cur_height=_height/_y_image_parts;

			int x_offset = cur_width*buf_prop.cur_x_img_part;
			int y_offset = cur_height*buf_prop.cur_y_img_part;

			if(buf_prop.cur_x_img_part == _x_image_parts-1)
			{
				cur_width = _width-(_x_image_parts-1)*(int)(_width/_x_image_parts);
			}
			if(buf_prop.cur_y_img_part == _y_image_parts-1)
			{
				cur_height = _height-(_y_image_parts-1)*(int)(_height/_y_image_parts);
			}

			if(buf_prop.fb!=0)
			{
				glViewport(0, 0,cur_width, cur_height);
			}
			else
			{
				glViewport(0, 0,_width, _height);
			}

			if(buf_prop.fb!=0)
			{
				buf_prop.cur_x_img_part += 1;
				if(buf_prop.cur_x_img_part == _x_image_parts)
				{
					buf_prop.cur_x_img_part = 0;
					buf_prop.cur_y_img_part += 1;

					if(buf_prop.cur_y_img_part == _y_image_parts)
					{
						buf_prop.cur_y_img_part = 0;
					}
				}
			}

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
			glUniform2f(buf_prop.offset_loc, (float)x_offset, (float)y_offset);

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

			if(buf_prop.fb!=0){
				glCopyImageSubData(_tile_render_buf,GL_RENDERBUFFER,0,0,0,0,buf_prop.tex_id_out_back,GL_TEXTURE_2D,0,x_offset,y_offset,0,cur_width,cur_height,1);
			}

			glFinish();

			return time_after - time_before;
		}
	}
}
