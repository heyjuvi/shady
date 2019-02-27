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
		public bool paused
		{
			get { return _paused; }
			set
			{
				if (value == true)
				{
					_pause_time = get_monotonic_time();
					Source.remove(_render_timeout);
				}
				else
				{
					_start_time += get_monotonic_time() - _pause_time;
					_render_timeout = Timeout.add(_timeout_interval, render_image);
				}

				_paused = value;
			}
		}

		public double time_slider
		{
			get {return _time_slider; }
			set
			{
				if(value == 0.0)
				{
					Source.remove(_render_timeout);
				}
				else if(_time_slider == 0.0)
				{
					_render_timeout = Timeout.add(_timeout_interval, render_image);
				}
				_time_slider = value;
			}
		}

		private GLuint _tile_render_buf;
		private uint _render_timeout;

		private GLib.Settings _settings = new GLib.Settings("org.hasi.shady");

		/* Buffer properties structs*/
		private RenderResources.BufferProperties _target_prop = new RenderResources.BufferProperties();

		private RenderResources _render_resources = new RenderResources();
		private CompileResources _compile_resources = new CompileResources();

		/* Constants */
		const uint _default_tile_size=16;
		const uint _timeout_interval=16;

		const double _target_time=10000.0;
		const double _upper_time_threshold=20000;
		const double _lower_time_threshold=5000;

		private bool _adaptive_tiling = true;

		private uint _x_image_parts = 1;
		private uint _y_image_parts = 1;

		/* OpenGL ids */

		private GLuint _resize_fb;

		/* Shader render buffer variables */

		private int64 _time_delta_accum = 0;

		private Mutex _size_mutex = Mutex();

		public ShadertoyArea()
		{
			realize.connect(() =>
			{
				_adaptive_tiling = _settings.get_boolean("adaptive-tiling");

				ShaderCompiler.initialize_pool();
				_compile_resources.window = get_window();
				_compile_resources.width = _width;
				_compile_resources.height = _height;

				init_gl(get_default_shader());
			});

			resize.connect((width, height) =>
			{
				update_size(width, height);
				update_rendering();
			});

			button_press_event.connect((widget, event) =>
			{
				if (event.button == BUTTON_PRIMARY)
				{
					_button_pressed = true;
					_button_pressed_x = event.x;
					_button_pressed_y = _height - event.y - 1;

					_render_timeout = Timeout.add(_timeout_interval, render_image);
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

					Source.remove(_render_timeout);
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
				if(!_paused)
				{
					Source.remove(_render_timeout);
				}

				//TODO: wait for compilation to finish
			});

			_compile_resources.compilation_finished.connect(() =>
			{
				compilation_finished();

				_x_image_parts = _width/_default_tile_size;
				_y_image_parts = _height/_default_tile_size;

				if(_width==0)
				{
					_x_image_parts = 8;
				}
				if(_height==0)
				{
					_y_image_parts = 8;
				}
				update_rendering();
			});

			_compile_resources.pass_compilation_terminated.connect((pass_index, e) =>
			{
				pass_compilation_terminated(pass_index,e);
			});
		}

		public void reset_time()
		{
			_start_time = _curr_time;
			_pause_time = _curr_time;
			update_rendering();
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

		private void init_tile_renderbuffer()
		{
			GLuint[] rb_arr = {0};
    		glGenRenderbuffers(1,rb_arr);
			_tile_render_buf=rb_arr[0];

    		glBindRenderbuffer(GL_RENDERBUFFER,_tile_render_buf);

			uint width=_width/_x_image_parts;
			uint height=_height/_x_image_parts;

			if(width<_width-(_x_image_parts-1)*width){
				width=_width-(_x_image_parts-1)*width;
			}
			if(height<_height-(_y_image_parts-1)*height){
				height=_height-(_y_image_parts-1)*height;
			}

    		glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA, (int)width, (int)height);
		}

		private void init_gl(Shader default_shader)
		{
			make_current();

			ShaderCompiler.compile_vertex_shader(_compile_resources);

			ShaderCompiler.init_compile_resources(_compile_resources);

			compile(default_shader);

			//TODO: properly wait for compilation to finish
			Thread.usleep(10000);

			RenderResources.BufferProperties img_prop = _render_resources.get_image_prop(RenderResources.Purpose.RENDER);

			GLuint vertex_shader_backup = _compile_resources.vertex_shader;
			init_target_pass(_target_prop, _compile_resources, img_prop.tex_id_out_front);

			//TODO: prevent fb from being generated
			_target_prop.fb=0;

			_compile_resources.vertex_shader = vertex_shader_backup;

			init_tile_renderbuffer();

			GLuint[] fb_arr = {0};

			glGenFramebuffers(1, fb_arr);
			_resize_fb = fb_arr[0];

			init_time();

			Gdk.GLContext.clear_current();

			_render_timeout = Timeout.add(_timeout_interval, render_image);

			add_events(EventMask.BUTTON_PRESS_MASK |
					   EventMask.BUTTON_RELEASE_MASK |
					   EventMask.POINTER_MOTION_MASK);
		}

		private void update_rendering()
		{
			Timeout.add(_timeout_interval, () =>
			{
				render_image();
				return false;
			});
		}

		//TODO: merge with init_tile_renderbuffer
		private void render_size_update(RenderResources.BufferProperties img_prop, RenderResources.BufferProperties[] buf_props)
		{
			make_current();

			_compile_resources.width = _width;
			_compile_resources.height = _height;

			glBindRenderbuffer(GL_RENDERBUFFER, _tile_render_buf);

			uint width=_width/_x_image_parts;
			uint height=_height/_x_image_parts;

			if(width < _width - (_x_image_parts-1) * width){
				width = _width - (_x_image_parts-1) * width;
			}
			if(height < _height - (_y_image_parts-1) * height){
				height = _height - (_y_image_parts-1) * height;
			}

			glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA, (int)width, (int)height);

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

		private void detect_tile_size(RenderResources.BufferProperties img_prop, double time_delta)
		{
			double target_tile_size = Math.sqrt((_target_time*(double)_width*(double)_height)/((double)time_delta*(double)_x_image_parts*(double)_y_image_parts));
			_x_image_parts = (uint)(_width/target_tile_size + 0.5);
			_y_image_parts = (uint)(_height/target_tile_size + 0.5);

			if(_x_image_parts < 1)
			{
				_x_image_parts = 1;
			}
			else if(_x_image_parts > _width)
			{
				_x_image_parts = _width;
			}

			if(_y_image_parts < 1)
			{
				_y_image_parts = 1;
			}
			else if(_y_image_parts > _height)
			{
				_y_image_parts = _height;
			}

			img_prop.cur_x_img_part = 0;
			img_prop.cur_y_img_part = 0;
		}

		private void swap_buffer_textures(RenderResources.BufferProperties[] buf_props, RenderResources.BufferProperties img_prop){
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
						img_prop.tex_ids[buf_props[i].tex_out_refs_img[j]] = tmp;
					}
				}
			}
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
					render_size_update(img_prop, buf_props);
				}

				if(img_prop.cur_x_img_part == 0 && img_prop.cur_y_img_part == 0)
				{
					update_uniform_values();
				}

				for(int i=0; i<buf_props.length; i++)
				{
					render_gl(buf_props[i]);
				}

				swap_buffer_textures(buf_props, img_prop);

				int64 time_delta = render_gl(img_prop);
				_time_delta_accum += time_delta;

				if(time_delta > _upper_time_threshold || time_delta < _lower_time_threshold)
				{
					detect_tile_size(img_prop, time_delta);
				}

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
			buf_prop.context.make_current();

			if(buf_prop.fb!=0)
			{
				glBindFramebuffer(GL_DRAW_FRAMEBUFFER, buf_prop.fb);
    			glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _tile_render_buf);
			}

			uint cur_width=_width/_x_image_parts;
			uint cur_height=_height/_y_image_parts;

			uint x_offset = cur_width*buf_prop.cur_x_img_part;
			uint y_offset = cur_height*buf_prop.cur_y_img_part;

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
				glViewport(0, 0,(int)cur_width, (int)cur_height);
			}
			else
			{
				glViewport(0, 0,(int)_width, (int)_height);
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

			set_uniform_values(buf_prop);
			glUniform2f(buf_prop.offset_loc, (float)x_offset, (float)y_offset);

			glBindVertexArray(buf_prop.vao);

			glFinish();

			time_before = get_monotonic_time();

			glDrawArrays(GL_TRIANGLES, 0, 3);

			glFlush();
			glFinish();

			time_after = get_monotonic_time();

			glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);

			if(buf_prop.fb!=0){
				glCopyImageSubData(_tile_render_buf,GL_RENDERBUFFER,0,0,0,0,buf_prop.tex_id_out_back,GL_TEXTURE_2D,0,(int)x_offset,(int)y_offset,0,(int)cur_width,(int)cur_height,1);
			}

			glFinish();

			return time_after - time_before;
		}
	}
}
