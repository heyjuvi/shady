namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-editor.ui")]
	public class ShaderEditor : Gtk.Box
	{
	    // TODO: bad solution?
	    private bool _edited;
		public bool edited
		{
			get { return _edited; }
			default = false;
		}

		public Shader shader
		{
		    get { return _curr_shader; }
		}

	    [GtkChild]
	    private Gtk.Notebook notebook;

	    [GtkChild]
	    private NotebookActionWidget action_widget;

	    [GtkChild]
	    private Gtk.Revealer channels_revealer;

	    [GtkChild]
	    private Gtk.Box channels_box;

		private ShaderChannel _channel_0;
		private ShaderChannel _channel_1;
		private ShaderChannel _channel_2;
		private ShaderChannel _channel_3;

		private HashTable<string, ShaderSourceBuffer> _shader_buffers = new HashTable<string, ShaderSourceBuffer>(str_hash, str_equal);

		private string _default_code;
		private string _buffer_default_code;

        private Shader _curr_shader;
		private ShaderSourceBuffer _curr_buffer;

		public ShaderEditor()
		{
			try
			{
				_default_code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/default.glsl", 0).get_data());
				_buffer_default_code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/buffer_default.glsl", 0).get_data());
			}
			catch (Error e)
			{
				print("Couldn't load default shader!\n");
			}

			_curr_shader = ShaderManager.get_default_shader();

			add_buffer("Image", false);
			set_buffer("Image", _default_code);

			_curr_buffer = _shader_buffers["Image"];

			_edited = false;

			ShaderChannel _channel_0 = new ShaderChannel();
			_channel_0.channel_name = "iChannel0";
			_channel_0.channel_input_changed.connect(channel_input_changed);

			ShaderChannel _channel_1 = new ShaderChannel();
			ShaderChannel _channel_2 = new ShaderChannel();
			ShaderChannel _channel_3 = new ShaderChannel();

			channels_box.pack_start(_channel_0, false, true);
			channels_box.pack_start(_channel_1, false, true);
			channels_box.pack_start(_channel_2, false, true);
			channels_box.pack_start(_channel_3, false, true);
		}

		public void gather_shader()
		{
		    for (int i = 0; i < _curr_shader.renderpasses.length; i++)
			{
				if (_curr_shader.renderpasses.index(i).type == Shader.RenderpassType.IMAGE)
				{
					_curr_shader.renderpasses.index(i).code = get_buffer("Image");
					//_shader_buffers["Image"].clear_error_messages();
				}

				if (_curr_shader.renderpasses.index(i).type == Shader.RenderpassType.BUFFER)
				{
					string renderpass_name = _curr_shader.renderpasses.index(i).name;
					_curr_shader.renderpasses.index(i).code = get_buffer(renderpass_name);
					//_shader_buffers[renderpass_name].clear_error_messages();
				}
			}
		}

		public void add_error_message(string buffer, int line, string name, string message)
		{
		    _shader_buffers[buffer].add_error_message(line, name, message);
		}

		public void clear_error_messages()
		{
		    foreach (string key in _shader_buffers.get_keys())
		    {
		        _shader_buffers[key].clear_error_messages();
		    }
		}

		private Shader.Renderpass find_current_renderpass()
		{
			Shader.Renderpass curr_renderpass = null;

			for (int i = 0; i < _curr_shader.renderpasses.length; i++)
			{
				if (_curr_shader.renderpasses.index(i).name == _curr_buffer.buf_name)
				{
					curr_renderpass = _curr_shader.renderpasses.index(i);
				}
			}

			return curr_renderpass;
		}

		private int add_buffer(string buffer_name, bool show_close_button=true)
		{
			ShaderSourceBuffer shader_buffer = new ShaderSourceBuffer(buffer_name);
			shader_buffer.buffer.changed.connect(() =>
			{
				_edited = true;
			});

			shader_buffer.button_press_event.connect((widget, event) =>
			{
				channels_revealer.reveal_child = false;

				return false;
			});

			NotebookTabLabel shader_buffer_label = new NotebookTabLabel.with_title(buffer_name);
			shader_buffer_label.show_close_button = show_close_button;
			shader_buffer_label.close_clicked.connect(() =>
			{
				remove_buffer(buffer_name);
			});

			_shader_buffers.insert(buffer_name, shader_buffer);
			return notebook.append_page(shader_buffer, shader_buffer_label);
		}

		private string add_buffer_alphabetically()
		{
			int i = 0;

			string buffer_name = @"Buf $((char) (0x41 + i))";
			while (buffer_name in _shader_buffers)
			{
				i++;
				buffer_name = @"Buf $((char) (0x41 + i))";
			}

			int new_page_num = add_buffer(buffer_name);
			set_buffer(buffer_name, _buffer_default_code);
			notebook.set_current_page(new_page_num);

			return buffer_name;
		}

		public void set_buffer(string buffer_name, string content)
		{
			_shader_buffers[buffer_name].buffer.text = content;
		}

		public string get_buffer(string buffer_name)
		{
			return _shader_buffers[buffer_name].buffer.text;
		}

		private void remove_buffer(string buffer_name)
		{
			notebook.remove_page(notebook.page_num(_shader_buffers[buffer_name]));
			_shader_buffers.remove(buffer_name);
		}

		public void set_shader(Shader? shader)
		{
			_shader_buffers.remove_all();

			for (int i = 0; i < notebook.get_n_pages(); i++)
			{
				notebook.remove_page(i);
			}

			if (shader != null)
			{
				List<string> sorted_keys = new List<string>();

				Shader.Renderpass sound_renderpass = null;
				Shader.Renderpass image_renderpass = null;

				for (int i = 0; i < shader.renderpasses.length; i++)
				{
					if (shader.renderpasses.index(i) is Shader.Renderpass)
					{
						Shader.Renderpass renderpass = shader.renderpasses.index(i) as Shader.Renderpass;

						if (renderpass.type == Shader.RenderpassType.SOUND)
						{
							sound_renderpass = renderpass;
						}
						else if (renderpass.type == Shader.RenderpassType.IMAGE)
						{
							image_renderpass = renderpass;
						}
						else
						{
							sorted_keys.insert_sorted(renderpass.name, strcmp);
						}
					}
				}

				if (sound_renderpass != null)
				{
					add_buffer("Sound", false);
					set_buffer("Sound", sound_renderpass.code);
				}

				if (image_renderpass != null)
				{
					add_buffer("Image", false);
					set_buffer("Image", image_renderpass.code);
				}

				foreach (string renderpass_name in sorted_keys)
				{
					for (int i = 0; i < shader.renderpasses.length; i++)
					{
						if (shader.renderpasses.index(i) is Shader.Renderpass)
						{
							Shader.Renderpass renderpass = shader.renderpasses.index(i) as Shader.Renderpass;

							if (renderpass.name == renderpass_name)
							{
								add_buffer(renderpass_name);
								set_buffer(renderpass_name, renderpass.code);
							}
						}
					}
				}
			}
		}

		[GtkCallback]
		private void add_renderpass()
		{
			string renderpass_name = add_buffer_alphabetically();

			Shader.Renderpass renderpass = new Shader.Renderpass();

			renderpass.name = renderpass_name;
			renderpass.code = _buffer_default_code;
			renderpass.type = Shader.RenderpassType.BUFFER;

			_curr_shader.renderpasses.append_val(renderpass);
		}

        [GtkCallback]
		private void toggle_channels()
		{
		    channels_revealer.reveal_child = !channels_revealer.reveal_child;
		}

		private void channel_input_changed(Shader.Input channel_input)
		{
		    if (channel_input.resource == null)
			{
				return;
			}

			Shader.Renderpass curr_renderpass = find_current_renderpass();
			if (curr_renderpass == null)
			{
				return;
			}

			if (curr_renderpass.inputs.length >= 1)
			{
				curr_renderpass.inputs.data[0] = channel_input;
			}
			else
			{
				curr_renderpass.inputs.append_val(channel_input);
			}
			//compile();

		}

		[GtkCallback]
		private void switch_buffer(Gtk.Notebook sender_notebook, Gtk.Widget buffer, uint page_num)
		{
		    _curr_buffer = buffer as ShaderSourceBuffer;
		}
	}
}
