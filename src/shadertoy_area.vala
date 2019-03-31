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

		private uint _render_timeout;

		private GLib.Settings _settings = new GLib.Settings("org.hasi.shady");

		/* Buffer properties structs*/
		private RenderResources.BufferProperties _target_prop = new RenderResources.BufferProperties();

		private RenderResources _render_resources = new RenderResources();
		private CompileResources _compile_resources = new CompileResources();

		/* Constants */
		const uint _timeout_interval=16;

		const double _target_time=10000.0;
		const double _upper_time_threshold=20000;
		const double _lower_time_threshold=5000;

		private bool _adaptive_tiling = true;

		/* OpenGL ids */

		private bool _image_updated = true;

		/* Shader render buffer variables */

		private int64 _time_delta_accum = 0;

		const double _fps_interval = 0.1;
		double _fps_sum = 0.0;
		int _num_fps_vals = 0;
		private int64 _fps_time;

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

					if(_paused)
					{
						_render_timeout = Timeout.add(_timeout_interval, render_image);
					}
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

					if(_paused)
					{
						Source.remove(_render_timeout);
					}
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
				_fps_sum = 0.0;
				_num_fps_vals = 0;
				_fps_time = get_monotonic_time();
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

		private void init_gl(Shader default_shader)
		{
			make_current();

			ShaderCompiler.compile_vertex_shader(_compile_resources);

			ShaderCompiler.init_compile_resources(_compile_resources);

			compile(default_shader);

			_compile_resources.ready_mutex.lock();
			_compile_resources.cond.wait(_compile_resources.ready_mutex);
			_compile_resources.ready_mutex.unlock();

			RenderResources.BufferProperties img_prop = _render_resources.get_image_prop(RenderResources.Purpose.RENDER);

			GLuint vertex_shader_backup = _compile_resources.vertex_shader;
			init_target_pass(_target_prop, _compile_resources, img_prop.tex_id_out_front);

			_compile_resources.vertex_shader = vertex_shader_backup;

			init_time();
			_fps_time = _start_time;

			Gdk.GLContext.clear_current();

			_render_timeout = Timeout.add(_timeout_interval, render_image);

			add_events(EventMask.BUTTON_PRESS_MASK |
					   EventMask.BUTTON_RELEASE_MASK |
					   EventMask.POINTER_MOTION_MASK);
		}

		private void update_rendering()
		{
			//render twice to fill up front and back buffer
			for(int i=0;i<2;i++)
			{
				if(_initialized && _paused && _image_updated)
				{
					Timeout.add(_timeout_interval, () =>
					{
						RenderResources.BufferProperties[] buf_props = _render_resources.get_buffer_props(RenderResources.Purpose.RENDER);

						_image_updated = false;

						for(int j=0;j<buf_props.length;j++)
						{
							buf_props[j].updated = false;
						}

						render_image();

						bool all_updated = true;
						for(int j=0;j<buf_props.length;j++)
						{
							all_updated &= buf_props[j].updated;
						}

						_image_updated = all_updated;

						if(_image_updated)
						{
							return false;
						}
						else
						{
							return true;
						}
					});
				}
			}
		}

		private void render_size_update(RenderResources.BufferProperties[] buf_props)
		{
			make_current();

			_compile_resources.width = _width;
			_compile_resources.height = _height;

			for(int i=0; i<buf_props.length; i++)
			{
				buf_props[i].cur_x_img_part = 0;
				buf_props[i].cur_y_img_part = 0;

				glBindRenderbuffer(GL_RENDERBUFFER, buf_props[i].tile_render_buf);
				glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA, (int)_width, (int)_height);

				glBindTexture(GL_TEXTURE_2D, buf_props[i].tex_id_out_back);
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});

				buf_props[i].second_resize = true;
			}

			_size_updated = false;
		}

		private void detect_tile_size(RenderResources.BufferProperties buf_prop, double time_delta)
		{
			double target_tile_size = Math.sqrt((_target_time*(double)_width*(double)_height)/((double)time_delta*(double)buf_prop.x_img_parts*(double)buf_prop.y_img_parts));
			buf_prop.x_img_parts = (uint)(_width/target_tile_size + 0.5);
			buf_prop.y_img_parts = (uint)(_height/target_tile_size + 0.5);

			if(buf_prop.x_img_parts < 1)
			{
				buf_prop.x_img_parts = 1;
			}
			else if(buf_prop.x_img_parts > _width)
			{
				buf_prop.x_img_parts = _width;
			}

			if(buf_prop.y_img_parts < 1)
			{
				buf_prop.y_img_parts = 1;
			}
			else if(buf_prop.y_img_parts > _height)
			{
				buf_prop.y_img_parts = _height;
			}

			buf_prop.cur_x_img_part = 0;
			buf_prop.cur_y_img_part = 0;
		}

		private void swap_buffer_textures(RenderResources.BufferProperties[] buf_props){
			for(int i=0; i<buf_props.length; i++)
			{
				if(buf_props[i].parts_rendered)
				{
					uint tmp = buf_props[i].tex_id_out_back;
					buf_props[i].tex_id_out_back = buf_props[i].tex_id_out_front;
					buf_props[i].tex_id_out_front = tmp;

					for(int j=0; j<buf_props[i].tex_out_refs.length[0]; j++)
					{
						buf_props[buf_props[i].tex_out_refs[j,0]].tex_ids[buf_props[i].tex_out_refs[j,1]] = tmp;
						buf_props[buf_props[i].tex_out_refs[j,0]].tex_widths[buf_props[i].tex_out_refs[j,1]] = _width;
						buf_props[buf_props[i].tex_out_refs[j,0]].tex_heights[buf_props[i].tex_out_refs[j,1]] = _height;
					}
					buf_props[i].parts_rendered = false;

					if(buf_props[i].second_resize)
					{
						glBindTexture(GL_TEXTURE_2D, buf_props[i].tex_id_out_back);
						glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});

						buf_props[i].second_resize = false;
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
					render_size_update(buf_props);
				}

				if(img_prop.cur_x_img_part == 0 && img_prop.cur_y_img_part == 0)
				{
					update_uniform_values();
				}

				for(int i=0; i<buf_props.length; i++)
				{
					int64 time_delta = render_gl(buf_props[i]);

					if(time_delta > _upper_time_threshold || time_delta < _lower_time_threshold)
					{
						detect_tile_size(buf_props[i], time_delta);
					}

					_time_delta_accum += time_delta * buf_props[i].x_img_parts * buf_props[i].y_img_parts;
				}

				if(img_prop.parts_rendered)
				{
					_target_prop.tex_ids[0] = img_prop.tex_id_out_back;
				}

				swap_buffer_textures(buf_props);

				double current_fps = 1000000.0 / (_time_delta_accum);
				int64 cur_time = get_monotonic_time();

				if((cur_time - _fps_time) / 1000000.0 < _fps_interval)
				{
					_fps_sum += current_fps;
					_num_fps_vals++;
				}
				else
				{
					if(_num_fps_vals != 0)
					{
						fps = _fps_sum / _num_fps_vals;
					}
					_fps_sum = 0.0;
					_num_fps_vals = 0;
					_fps_time = cur_time;
				}

				_time_delta_accum = 0;

				_size_mutex.unlock();
			}
			_render_resources.buffer_switch_mutex.unlock();

			return true;
		}

		private int64 render_gl(RenderResources.BufferProperties buf_prop)
		{
			buf_prop.context.make_current();

			uint x_offset = 0;
			uint y_offset = 0;
			uint cur_width = 0;
			uint cur_height = 0;

			if(buf_prop.fb!=0)
			{
				glBindFramebuffer(GL_DRAW_FRAMEBUFFER, buf_prop.fb);
    			glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, buf_prop.tile_render_buf);

				cur_width=_width/buf_prop.x_img_parts;
				cur_height=_height/buf_prop.y_img_parts;

				x_offset = cur_width*buf_prop.cur_x_img_part;
				y_offset = cur_height*buf_prop.cur_y_img_part;

				if(buf_prop.cur_x_img_part == buf_prop.x_img_parts-1)
				{
					cur_width = _width-(buf_prop.x_img_parts-1)*(int)(_width/buf_prop.x_img_parts);
				}
				if(buf_prop.cur_y_img_part == buf_prop.y_img_parts-1)
				{
					cur_height = _height-(buf_prop.y_img_parts-1)*(int)(_height/buf_prop.y_img_parts);
				}

				glViewport(0, 0,(int)cur_width, (int)cur_height);

				buf_prop.cur_x_img_part += 1;
				if(buf_prop.cur_x_img_part >= buf_prop.x_img_parts)
				{
					buf_prop.cur_x_img_part = 0;
					buf_prop.cur_y_img_part += 1;

					if(buf_prop.cur_y_img_part >= buf_prop.y_img_parts)
					{
						buf_prop.cur_y_img_part = 0;
						buf_prop.parts_rendered = true;
						buf_prop.updated = true;
					}
				}
			}
			else
			{
				glViewport(0, 0,(int)_width, (int)_height);
			}

			int64 time_after = 0, time_before = 0;

			glUseProgram(buf_prop.program);

			set_uniform_values(buf_prop);
			glUniform2f(buf_prop.offset_loc, (float)x_offset, (float)y_offset);

			glBindVertexArray(buf_prop.vao);

			glFinish();

			time_before = get_monotonic_time();

			glDrawArrays(GL_TRIANGLES, 0, 3);

			glFinish();

			time_after = get_monotonic_time();

			glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);

			if(buf_prop.fb!=0){
				glCopyImageSubData(buf_prop.tile_render_buf,GL_RENDERBUFFER,0,0,0,0,buf_prop.tex_id_out_back,GL_TEXTURE_2D,0,(int)x_offset,(int)y_offset,0,(int)cur_width,(int)cur_height,1);
			}

			glFinish();

			return time_after - time_before;
		}
	}
}
