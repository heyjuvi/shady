namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-editor.ui")]
	public class ShaderEditor : Gtk.Overlay
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

	    private int _buffer_chars;
	    public int buffer_chars
	    {
	        get { return _buffer_chars; }
	        set
	        {
	            _buffer_chars = value;
	            refresh_chars_label();
	        }
	    }

	    private int _total_chars;
	    public int total_chars
	    {
	        get { return _total_chars; }
	        set
	        {
	            _total_chars = value;
	            refresh_chars_label();
	        }
	    }

		/*public unowned string[] buffers
		{
		    get
		    {
		        string[] keys;
		        foreach (string key in _shader_buffers.get_keys())
		        {
		            keys += key;
		        }

		        return keys;
		    }
		}*/

		public signal void buffer_switched(ShaderSourceBuffer from, ShaderSourceBuffer to);

		[GtkChild]
		private Gtk.Revealer search_revealer;

		[GtkChild]
		private Gtk.SearchEntry search_entry;

	    [GtkChild]
	    private Gtk.Notebook notebook;

	    [GtkChild]
	    private Gtk.Label chars_label;

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

		private Gtk.TextIter _last_match_start;
		private Gtk.TextIter _last_match_end;

		private Core.GLSLMinifier _minifier;

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

			_minifier = new Core.GLSLMinifier();

			_curr_shader = ShaderManager.get_default_shader();

			add_buffer("Image", false);
			set_buffer("Image", _default_code);

			do_full_char_count_refresh();

			_edited = false;

			_channel_0 = new ShaderChannel();
			_channel_0.channel_name = "iChannel0";
			_channel_0.channel_input_changed.connect(channel_input_changed);

			_channel_1 = new ShaderChannel();
			_channel_1.channel_name = "iChannel1";

			_channel_2 = new ShaderChannel();
			_channel_2.channel_name = "iChannel2";

			_channel_3 = new ShaderChannel();
			_channel_3.channel_name = "iChannel3";

			channels_box.pack_start(_channel_0, false, true);
			channels_box.pack_start(_channel_1, false, true);
			channels_box.pack_start(_channel_2, false, true);
			channels_box.pack_start(_channel_3, false, true);

			buffer_switched.connect((from, to) =>
			{
			    // we always need valid iters
			    Gtk.TextIter cursor_iter;
                to.buffer.get_iter_at_offset(out cursor_iter, to.buffer.cursor_position);

                _last_match_start = cursor_iter;
		        _last_match_end = cursor_iter;
			});

			search_entry.key_press_event.connect((widget, event) =>
			{
			    if (event.keyval == Gdk.Key.Down)
				{
					search_forward();
					return true;
				}

				if (event.keyval == Gdk.Key.Up)
				{
					search_backward();
					return true;
				}

				if (event.keyval == Gdk.Key.Return)
				{
					hide_search();
				}

				return false;
			});

			search_entry.focus_out_event.connect(() =>
			{
			    hide_search();

			    return false;
			});
		}

		public void show_search()
		{
		    // always valid iters
		    Gtk.TextIter cursor_iter;
            _curr_buffer.buffer.get_iter_at_offset(out cursor_iter, _curr_buffer.buffer.cursor_position);

            _last_match_start = cursor_iter;
		    _last_match_end = cursor_iter;

            _curr_buffer.search_context.highlight = true;
		    search_revealer.reveal_child = true;
		    search_entry.grab_focus();
		}

		public void hide_search()
		{
		    _curr_buffer.search_context.highlight = false;
		    search_revealer.reveal_child = false;
		    _curr_buffer.view.grab_focus();
		}

		public void next_buffer()
		{
		    if (notebook.get_current_page() == notebook.get_n_pages() - 1)
		    {
		        notebook.set_current_page(0);
		    }
		    else
		    {
		        notebook.next_page();
		    }
		}

		public void prev_buffer()
		{
		    if (notebook.get_current_page() == 0)
		    {
		        notebook.set_current_page(notebook.get_n_pages() - 1);
		    }
		    else
		    {
		        notebook.prev_page();
		    }
		}

		[GtkCallback]
		private void search_changed()
		{
		    Gtk.TextIter cursor_iter;
            _curr_buffer.buffer.get_iter_at_offset(out cursor_iter, _curr_buffer.buffer.cursor_position);

            _last_match_start = cursor_iter;
		    _last_match_end = cursor_iter;

            _curr_buffer.search_context.settings.search_text = search_entry.text;
            _curr_buffer.search_context.settings.wrap_around = true;
		    _curr_buffer.search_context.forward_async.begin(cursor_iter, null, (object, resource) =>
		    {
		        Gtk.TextIter match_start, match_end;
		        bool results;

		        bool match_found = _curr_buffer.search_context.forward_async.end(resource, out match_start, out match_end, out results);

		        if (match_found)
		        {
		            _last_match_start = match_start;
		            _last_match_end = match_end;
		        }
		    });
		}

		[GtkCallback]
		private void search_forward()
		{
		    _curr_buffer.search_context.forward_async.begin(_last_match_end, null, (object, resource) =>
		    {
		        Gtk.TextIter match_start, match_end;
		        bool results;

		        bool match_found = _curr_buffer.search_context.forward_async.end(resource, out match_start, out match_end, out results);

                if (match_found)
                {
                    _curr_buffer.buffer.select_range(match_start, match_end);
                    _curr_buffer.view.scroll_to_iter(match_start, 0.0, true, 0.5, 0.5);

                    _last_match_start = match_start;
		            _last_match_end = match_end;
		        }
		    });
		}

		[GtkCallback]
		private void search_backward()
		{
		    _curr_buffer.search_context.backward_async.begin(_last_match_start, null, (object, resource) =>
		    {
		        Gtk.TextIter match_start, match_end;
		        bool results;

		        bool match_found = _curr_buffer.search_context.backward_async.end(resource, out match_start, out match_end, out results);

                if (match_found)
                {
                    _curr_buffer.buffer.select_range(match_start, match_end);

                    _last_match_start = match_start;
		            _last_match_end = match_end;
		        }
		    });
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
				if (_curr_shader.renderpasses.index(i).name == _curr_buffer.buffer_name)
				{
					curr_renderpass = _curr_shader.renderpasses.index(i);
				}
			}

			return curr_renderpass;
		}

		private void refresh_chars_label()
		{
		    chars_label.set_markup(@"<b>$_buffer_chars</b>/$_total_chars");
		}

		private void do_full_char_count_refresh()
		{
		    int new_total_chars = 0;
			foreach (string key in _shader_buffers.get_keys())
			{
			    new_total_chars += _minifier.minify_kindly(_shader_buffers[key].buffer.text).length;
			}

			buffer_chars = _minifier.minify_kindly(_curr_buffer.buffer.text).length;
			total_chars = new_total_chars;
		}

		private int add_buffer(string buffer_name, bool show_close_button=true)
		{
			ShaderSourceBuffer shader_buffer = new ShaderSourceBuffer(buffer_name);
			shader_buffer.buffer.changed.connect(() =>
			{
			    // valid iters
			    Gtk.TextIter cursor_iter;
                shader_buffer.buffer.get_iter_at_offset(out cursor_iter, shader_buffer.buffer.cursor_position);

                _last_match_start = cursor_iter;
		        _last_match_end = cursor_iter;

		        int new_total_chars = total_chars - buffer_chars;
		        int new_buffer_chars = _minifier.minify_kindly(shader_buffer.buffer.text).length;

		        new_total_chars += new_buffer_chars;

		        buffer_chars = new_buffer_chars;
		        total_chars = new_total_chars;

				_edited = true;
			});

			shader_buffer.view.grab_focus.connect(() =>
			{
			    _curr_buffer.search_context.highlight = false;
		        search_revealer.reveal_child = false;
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
			int num = notebook.append_page(shader_buffer, shader_buffer_label);

            shader_buffer.show();

			return num;
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

			switch_buffer(buffer_name);

		    do_full_char_count_refresh();

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

		public bool switch_buffer(string buffer_name)
		{
		    for (int i = 0; i < notebook.get_n_pages(); i++)
		    {
		        ShaderSourceBuffer shader_buffer = notebook.get_nth_page(i) as ShaderSourceBuffer;
		        if (shader_buffer.buffer_name == buffer_name)
		        {
		            notebook.set_current_page(i);
		            return true;
		        }
		    }

		    return false;
		}

		private void remove_buffer(string buffer_name)
		{
			notebook.remove_page(notebook.page_num(_shader_buffers[buffer_name]));
			_shader_buffers.remove(buffer_name);

			do_full_char_count_refresh();
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
		private void switch_page(Gtk.Notebook sender_notebook, Gtk.Widget buffer, uint page_num)
		{
		    buffer_switched(_curr_buffer, buffer as ShaderSourceBuffer);

		    _curr_buffer = buffer as ShaderSourceBuffer;
		    buffer_chars = _minifier.minify_kindly(_curr_buffer.buffer.text).length;
		}
	}
}
