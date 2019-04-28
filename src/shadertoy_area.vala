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
					if(!_paused)
					{
						Source.remove(_render_timeout);
					}
				}
				else
				{
					_start_time += get_monotonic_time() - _pause_time;
					if(_paused)
					{
						_render_timeout = Timeout.add(_timeout_interval, render_image);
					}
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

		private enum KeyEvent
		{
			PRESSED,
			RELEASED,
			RENDERED;
		}

		private GLib.Settings _settings = new GLib.Settings("org.hasi.shady");

		/* Global Resources*/
		private RenderResources.BufferProperties _target_prop = new RenderResources.BufferProperties();

		private RenderResources _render_resources = new RenderResources();
		private CompileResources _compile_resources = new CompileResources();

		/* Constants */
		const uint _timeout_interval=16;

		const double _target_time=10000.0;
		const double _upper_time_threshold=20000;
		const double _lower_time_threshold=5000;

		const double _fps_interval = 0.1;

		/* Flags */
		private bool _image_updated = true;
		private bool _synchronized_rendering = false;

		/* Shader render buffer variables */
		private int64 _time_delta_accum = 0;

		private uint _render_timeout;
		private uchar[] _updated_keys = {};
		private bool[] _keys_pressed = new bool[256];

		double _fps_sum = 0.0;
		int _num_fps_vals = 0;
		private int64 _fps_time;

		private Mutex _size_mutex = Mutex();

		public ShadertoyArea(Shader default_shader)
		{
			can_focus = true;

			_synchronized_rendering = _settings.get_boolean("synchronized-rendering");

			realize.connect(() =>
			{
				ShaderCompiler.initialize_pool();
				_compile_resources.window = get_window();
				_compile_resources.width = _width;
				_compile_resources.height = _height;

				init_gl(default_shader);
			});

			resize.connect((width, height) =>
			{
				update_size(width, height);
				update_rendering();
			});

			key_press_event.connect((widget, event) =>
			{
				uchar keycode = compute_keycode(event);
				//TODO: is there a better way to prevent repeating?
				if(!_keys_pressed[keycode])
				{
					_keys_pressed[keycode] = true;
					update_keyboard_texture({keycode}, KeyEvent.PRESSED);
					_updated_keys += keycode;
				}

				return true;
			});

			key_release_event.connect((widget, event) =>
			{
				uchar keycode = compute_keycode(event);
				_keys_pressed[keycode] = false;
				update_keyboard_texture({keycode}, KeyEvent.RELEASED);

				return true;
			});

			button_press_event.connect((widget, event) =>
			{
				//why is this needed? (focus_on_click is true by default)
				grab_focus();

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
				update_time();
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
				_fps_sum = 0.0;
				_num_fps_vals = 0;
				_fps_time = get_monotonic_time();

				update_rendering();

				compilation_finished();
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

			RenderResources.BufferProperties[] buf_props = _render_resources.get_buffer_props(RenderResources.Purpose.RENDER);

			for(int i=0;i<buf_props.length;i++)
			{
				buf_props[i].frame_counter = 0;
			}

			reset_buffer_textures(buf_props);

			update_rendering();
		}

		public void compile(Shader shader)
		{
			ShaderCompiler.queue_shader_compile(shader, _render_resources, _compile_resources);
		}

		public void compile_main_thread(Shader shader)
		{
			make_current();
			ShaderCompiler.compile_main_thread(shader, _render_resources, _compile_resources);
			make_current();
		}

		private void init_gl(Shader default_shader)
		{
			make_current();

			ShaderCompiler.compile_vertex_shader(_compile_resources);

			ShaderCompiler.init_compile_resources(_compile_resources);

			compile_main_thread(default_shader);
			make_current();

			RenderResources.BufferProperties img_prop = _render_resources.get_image_prop(RenderResources.Purpose.RENDER);

			GLuint vertex_shader_backup = _compile_resources.vertex_shader;
			init_target_pass(_target_prop, _compile_resources, img_prop.tex_id_out_front);

			_compile_resources.vertex_shader = vertex_shader_backup;

			init_time();
			_fps_time = _start_time;

			GLContext.clear_current();

			_render_timeout = Timeout.add(_timeout_interval, render_image);

			add_events(EventMask.BUTTON_PRESS_MASK |
					   EventMask.BUTTON_RELEASE_MASK |
					   EventMask.POINTER_MOTION_MASK |
			           EventMask.KEY_PRESS_MASK);
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
				glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA32F, (int)_width, (int)_height);

				glBindTexture(GL_TEXTURE_2D, buf_props[i].tex_id_out_back);
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});

				buf_props[i].second_resize = true;
			}

			_size_updated = false;
		}

		private void update_keyboard_texture(uchar[] keycodes, KeyEvent event)
		{
			Shader.Input keyboard_input = new Shader.Input();
			keyboard_input.type = Shader.InputType.KEYBOARD;
			keyboard_input.resource_index = 0;
			GLuint target;

			int width = 0;
			int height = 0;
			int depth = 0;

			GLuint[] tex_ids = TextureManager.query_input_texture(keyboard_input, (uint64) get_window(), ref width, ref height, ref depth, out target);

			TextureManager.AuxBuffer buffer = TextureManager.query_aux_buffer(keyboard_input, (uint64) get_window());

			if(event == KeyEvent.RENDERED)
			{
				foreach(uchar keycode in keycodes)
				{
					buffer.data[keycode+width] = (char)0;
				}
			}
			else if(event == KeyEvent.PRESSED)
			{
				buffer.data[keycodes[0]+2*width] = (char)255 - buffer.data[keycodes[0]+2*width];
				buffer.data[keycodes[0]+width] = (char)255;
				buffer.data[keycodes[0]] = (char)255;
			}
			else if(event == KeyEvent.RELEASED)
			{
				buffer.data[keycodes[0]] = 0;
			}

			glBindTexture(target, tex_ids[0]);
			glTexImage2D(target, 0, GL_RED, width, height, 0, GL_RED, GL_UNSIGNED_BYTE, (GLvoid[])buffer.data);
		}

		private uchar compute_keycode(EventKey event)
		{
			//javascript always gets the unmodified key of the current keyboard layout, so we do the same
			KeymapKey key = KeymapKey();
			key.group = 0;
			key.level = 0;
			key.keycode = event.hardware_keycode;

			uint val = Keymap.get_for_display(get_display()).lookup_key(key);
			uchar js_keycode = Keycodes.keyval_to_js_keycode(val);

			return js_keycode;
		}

		private void reset_buffer_textures(RenderResources.BufferProperties[] buf_props)
		{
			make_current();

			for(int i=0; i<buf_props.length; i++)
			{
				buf_props[i].cur_x_img_part = 0;
				buf_props[i].cur_y_img_part = 0;

				float[] empty_buffer = new float[_width * _height * 4];

				glBindTexture(GL_TEXTURE_2D, buf_props[i].tex_id_out_front);
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid[])empty_buffer);

				glBindTexture(GL_TEXTURE_2D, buf_props[i].tex_id_out_back);
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid[])empty_buffer);
			}
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

		private void swap_buffer_textures(RenderResources.BufferProperties[] buf_props, RenderResources.BufferProperties img_prop){
			if(!_synchronized_rendering)
			{
				if(img_prop.parts_rendered)
				{
					_target_prop.tex_ids[0] = img_prop.tex_id_out_back;
				}
				for(int i=0; i<buf_props.length; i++)
				{
					if(buf_props[i].parts_rendered)
					{
						swap_buffer(buf_props, i);
						update_uniform_values(buf_props[i]);
					}
				}
			}
			else
			{
				bool all_buffer_rendered = true;
				for(int i=0; i<buf_props.length; i++)
				{
					all_buffer_rendered &= buf_props[i].parts_rendered;
				}

				if(all_buffer_rendered)
				{
					_target_prop.tex_ids[0] = img_prop.tex_id_out_back;

					update_uniform_values(buf_props[0]);
					swap_buffer(buf_props, 0);
					for(int i=1; i<buf_props.length; i++)
					{
						swap_buffer(buf_props, i);
						copy_buffer_time(buf_props[i], buf_props[0]);
					}
				}
			}
		}

		private void swap_buffer(RenderResources.BufferProperties[] buf_props, int i)
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
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, {});

				buf_props[i].second_resize = false;
			}
		}

		void update_fps()
		{
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

				for(int i=0; i<buf_props.length; i++)
				{
					if(!buf_props[i].parts_rendered)
					{
						int64 time_delta = render_gl(buf_props[i]);

						if(time_delta > _upper_time_threshold || time_delta < _lower_time_threshold)
						{
							detect_tile_size(buf_props[i], time_delta);
						}

						_time_delta_accum += time_delta * buf_props[i].x_img_parts * buf_props[i].y_img_parts;
					}
				}

				swap_buffer_textures(buf_props, img_prop);

				if(_updated_keys.length > 0)
				{
					update_keyboard_texture(_updated_keys, KeyEvent.RENDERED);
					_updated_keys = {};
				}

				update_fps();

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

			//glFinish();

			time_before = get_monotonic_time();

			glDrawArrays(GL_TRIANGLES, 0, 3);

			//glFinish();

			time_after = get_monotonic_time();

			glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);

			if(buf_prop.fb!=0){
				glCopyImageSubData(buf_prop.tile_render_buf,GL_RENDERBUFFER,0,0,0,0,buf_prop.tex_id_out_back,GL_TEXTURE_2D,0,(int)x_offset,(int)y_offset,0,(int)cur_width,(int)cur_height,1);
			}

			//glFinish();

			return time_after - time_before;
		}
	}
}
