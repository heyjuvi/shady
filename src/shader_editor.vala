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
			//default = false;
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

		private ShaderChannel[] _channels;
		private bool _channels_initialized;

		private HashTable<string, ShaderSourceBuffer> _shader_buffers;

        private Shader _curr_shader = null;
		private ShaderSourceBuffer _curr_buffer = null;

		private ulong change_renderpass_handler_id = 0;

		private Gtk.TextIter _last_match_start;
		private Gtk.TextIter _last_match_end;

        private Core.GLSlangValidator _validator;
		private Core.GLSLMinifier _minifier;

		private Mutex _minify_mutex = Mutex();

		private bool _destroyed = false;

		public ShaderEditor()
		{
		    _shader_buffers = new HashTable<string, ShaderSourceBuffer>(str_hash, str_equal);

            _validator = new Core.GLSlangValidator();
			_minifier = new Core.GLSLMinifier();

			_curr_shader = ShaderArea.get_default_shader();

		    bool sanity = Shader.RENDERPASSES_ORDER.get_keys().data.contains("Image");
		    debug(@"(shader-editor): sanity checking for Image: $sanity");
			add_buffer("Image", get_insert_index_for_buffer("Image"), false);
			set_buffer("Image", ShadertoyResourceManager.get_default_shader_by_buffer_name("Image"));

			_curr_buffer = _shader_buffers["Image"];

			do_full_char_count_refresh();

			_edited = false;

			_channels = new ShaderChannel[4];
			_channels_initialized = false;

            for (int i = 0; i < 4; i++)
            {
			    _channels[i] = new ShaderChannel(i);
			    _channels[i].channel_name = @"iChannel$i";

			    _channels[i].channel_input_changed.connect(channel_input_changed);

			    channels_box.pack_start(_channels[i], false, true);
			}

            // one channel is enough to indicate that all channels are initialized:
            // this is maybe a little bit hacky and not safe in terms of race conditions
		    _channels[0].channel_area.initialized.connect(() =>
		    {
		        debug("(shader_editor): channels have been initialized and will be updated now");
		        _channels_initialized = true;

		        update_channels_for_current_shader();

		        for (int i = 0; i < _channels.length; i++)
			    {
			        _channels[i].channel_buffer = _curr_buffer.buffer_name;
			    }
		    });

			buffer_switched.connect((from, to) =>
			{
			    // we always need valid iters
			    Gtk.TextIter cursor_iter;
                to.buffer.get_iter_at_offset(out cursor_iter, to.buffer.cursor_position);

                _last_match_start = cursor_iter;
		        _last_match_end = cursor_iter;
			});

			change_renderpass_handler_id = action_widget.buffer_active_changed.connect(change_renderpass);

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

			ThreadFunc<bool> run = () =>
		    {
		        while (!_destroyed)
		        {
		            if (_curr_buffer != null)
		            {
		                _minify_mutex.lock();

		                string? buffer_text = null;
		                Idle.add(() =>
	                    {
		                    buffer_text = _curr_buffer.buffer.text;

		                    return false;
		                });

		                while (buffer_text == null);;

	                    int new_total_chars = total_chars - buffer_chars;
	                    int new_buffer_chars = _minifier.minify_kindly(buffer_text).length;

	                    new_total_chars += new_buffer_chars;

	                    Timeout.add(0, () =>
	                    {
	                        buffer_chars = new_buffer_chars;
	                        total_chars = new_total_chars;

	                        _minify_mutex.unlock();

	                        return false;
	                    });
	                }

                    // TODO: this could in principle be made adaptive
	                Thread.usleep(2000000);
	            }

	            return true;
	        };
	        new Thread<bool>("minify_thread", (owned) run);
		}

		public void prepare_destruction()
		{
		    _destroyed = true;
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

				try
				{
					bool match_found = _curr_buffer.search_context.forward_async.end(resource, out match_start, out match_end, out results);

					if (match_found)
					{
						_last_match_start = match_start;
						_last_match_end = match_end;
					}
				}
				catch (Error e)
				{
				    warning(@"search_changed: $(e.message)");
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

				try
				{
					bool match_found = _curr_buffer.search_context.forward_async.end(resource, out match_start, out match_end, out results);

					if (match_found)
					{
						_curr_buffer.buffer.select_range(match_start, match_end);
						_curr_buffer.view.scroll_to_iter(match_start, 0.0, true, 0.5, 0.5);

						_last_match_start = match_start;
						_last_match_end = match_end;
					}
				}
				catch (Error e)
				{
					print("Error in forward search\n");
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

				try
				{
					bool match_found = _curr_buffer.search_context.backward_async.end(resource, out match_start, out match_end, out results);

					if (match_found)
					{
						_curr_buffer.buffer.select_range(match_start, match_end);

						_last_match_start = match_start;
						_last_match_end = match_end;
					}
				}
				catch (Error e)
				{
					print("Error in backward search\n");
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
				}
				else if (_curr_shader.renderpasses.index(i).type == Shader.RenderpassType.COMMON)
				{
					_curr_shader.renderpasses.index(i).code = get_buffer("Common");
				}
				else if (_curr_shader.renderpasses.index(i).type == Shader.RenderpassType.SOUND)
				{
					_curr_shader.renderpasses.index(i).code = get_buffer("Sound");
				}
				else if (_curr_shader.renderpasses.index(i).type == Shader.RenderpassType.BUFFER)
				{
					string renderpass_name = _curr_shader.renderpasses.index(i).renderpass_name;
					_curr_shader.renderpasses.index(i).code = get_buffer(renderpass_name);
				}
			}
		}

		public bool validate_shader()
		{
		    bool total_success = true;

		    gather_shader();

		    HashTable<string, string> sources = Core.SourceGenerator.generate_shader_source(_curr_shader, true);
		    //int compile_counter = (int) sources.get_keys().length();

            clear_error_messages();

		    foreach (string buffer in sources.get_keys())
		    {
		        string buffer_source = sources[buffer];

                Core.GLSlangValidator validator = new Core.GLSlangValidator();
		        validator.validate(buffer_source, (errors, success) =>
		        {
		            if (!success)
		            {
		                total_success = false;

		                //Shader.Renderpass renderpass = _curr_shader.get_renderpass_by_name(buffer);
		                foreach (Core.GLSlangValidator.CompileError error in errors)
		                {
		                    add_error_message(buffer, error.line, error.to_string_without_lines());
		                }
		            }
		        });
		    }

		    return total_success;
		}

		public void add_error_message(string buffer, int line, string message)
		{
		    _shader_buffers[buffer].add_error_message(line, @"buffer-$line", message);
		}

		public void clear_error_messages()
		{
		    foreach (string key in _shader_buffers.get_keys())
		    {
		        _shader_buffers[key].clear_error_messages();
		    }
		}

		private Shader.Renderpass? find_current_renderpass()
		{
		    if (_curr_buffer == null)
		    {
		        return null;
		    }

			Shader.Renderpass curr_renderpass = null;

			for (int i = 0; i < _curr_shader.renderpasses.length; i++)
			{
				if (_curr_shader.renderpasses.index(i).renderpass_name == _curr_buffer.buffer_name)
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
		    if (_curr_buffer == null)
		    {
		        return;
		    }

            ThreadFunc<bool> run = () =>
		    {
	            _minify_mutex.lock();

	            int new_total_chars = 0;

	            uint keys_length = _shader_buffers.get_keys().length();
	            int mark_curr_buffer = -1;

	            int buffers_fetched = 0;
	            Array<string> buffer_texts = new Array<string>();
		        foreach (string key in _shader_buffers.get_keys())
		        {
	                Timeout.add(0, () =>
                    {
	                    buffer_texts.append_val(_shader_buffers[key].buffer.text);

	                    if (_shader_buffers[key] == _curr_buffer)
	                    {
	                        mark_curr_buffer = buffers_fetched;
	                    }

	                    buffers_fetched++;

	                    return false;
	                });
	            }

	            while (buffers_fetched != keys_length);

                for (int i = 0; i < keys_length; i++)
                {
		            new_total_chars += _minifier.minify_kindly(buffer_texts.index(i)).length;
		        }

                int new_buffer_chars = 0;
                if (mark_curr_buffer >= 0)
                {
		            new_buffer_chars = _minifier.minify_kindly(buffer_texts.index(mark_curr_buffer)).length;
		        }

                Timeout.add(0, () =>
                {
                    buffer_chars = new_buffer_chars;
                    total_chars = new_total_chars;

                    _minify_mutex.unlock();

                    return false;
                });

	            return true;
	        };
	        new Thread<bool>("minify_full_thread", (owned) 	run);
		}

		private int add_buffer(string buffer_name, int insert_index, bool show_close_button=true, bool skip_full_char_refresh=false)
//		    requires(Shader.RENDERPASSES_ORDER.get_keys().data.contains(buffer_name))
		{
			ShaderSourceBuffer shader_buffer = new ShaderSourceBuffer(buffer_name);
			shader_buffer.buffer.changed.connect(() =>
			{
			    // valid iters
			    Gtk.TextIter cursor_iter;
                shader_buffer.buffer.get_iter_at_offset(out cursor_iter, shader_buffer.buffer.cursor_position);

                _last_match_start = cursor_iter;
		        _last_match_end = cursor_iter;

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
			    // triggers the removal, not sure, wether this could be solved more elegant
				action_widget.set_buffer_active(buffer_name, false);
			});

            debug(@"add_buffer: adding $buffer_name to shader buffers");
			_shader_buffers.insert(buffer_name, shader_buffer);

            debug(@"add_buffer: inserting new shader buffer into notebook");
			int num = notebook.insert_page(shader_buffer, shader_buffer_label, insert_index);

            shader_buffer.show();

            if (!skip_full_char_refresh)
            {
			    do_full_char_count_refresh();
			}

			return num;
		}

		public void set_buffer(string buffer_name, string content, bool skip_full_char_refresh=false)
//		    requires(_shader_buffers.get_keys().data.contains(buffer_name))
		{
			_shader_buffers[buffer_name].buffer.text = content;

            if (!skip_full_char_refresh)
            {
			    do_full_char_count_refresh();
			}
		}

		public string get_buffer(string buffer_name)
//		    requires(_shader_buffers.get_keys().data.contains(buffer_name))
		{
			return _shader_buffers[buffer_name].buffer.text;
		}

		public bool switch_buffer(string buffer_name)
//		    requires(_shader_buffers.get_keys().data.contains(buffer_name))
		{
		    for (int i = 0; i < notebook.get_n_pages(); i++)
		    {
		        ShaderSourceBuffer shader_buffer = notebook.get_nth_page(i) as ShaderSourceBuffer;
		        if (shader_buffer.buffer_name == buffer_name)
		        {
		            debug(@"switch_buffer: setting current page of notebook to $i, which is the current notebook index of $buffer_name");
		            notebook.set_current_page(i);
		            return true;
		        }
		    }

		    return false;
		}

		private void remove_buffer(string buffer_name, bool skip_full_char_refresh=false)
//		    requires(_shader_buffers.get_keys().data.contains(buffer_name))
		{
			debug("remove_buffer: removing $buffer_name from shader buffers");
			_shader_buffers.remove(buffer_name);

		    debug("remove_buffer: removing $buffer_name from notebook");
			notebook.remove_page(notebook.page_num(_shader_buffers[buffer_name]));

			for (int i = 0; i < shader.renderpasses.length; i++)
			{
			    if (shader.renderpasses.index(i).renderpass_name == buffer_name)
			    {
			        debug("remove_buffer: removing $buffer_name, which has index $i, from current shaders renderpasses");
			        _curr_shader.renderpasses.remove_index(i);

			        break;
			    }
			}

			if (!skip_full_char_refresh)
            {
			    do_full_char_count_refresh();
			}
		}

		private int get_insert_index_for_buffer(string buffer_name)
//		    requires(Shader.RENDERPASSES_ORDER.get_keys().data.contains(buffer_name))
		{
		    int insert_index = -1;
		    for (int i = 0; i < notebook.get_n_pages(); i++)
		    {
		        ShaderSourceBuffer? shader_buffer_before = notebook.get_nth_page(i) as ShaderSourceBuffer;
		        ShaderSourceBuffer? shader_buffer_after = notebook.get_nth_page(i + 1) as ShaderSourceBuffer;
		        if (shader_buffer_after == null)
		        {
		            insert_index = i + 1;
		            break;
		        }
		        else if (Shader.RENDERPASSES_ORDER[shader_buffer_before.buffer_name] < Shader.RENDERPASSES_ORDER[buffer_name] &&
		                 Shader.RENDERPASSES_ORDER[buffer_name] < Shader.RENDERPASSES_ORDER[shader_buffer_after.buffer_name])
		        {
		            insert_index = i + 1;
		            break;
		        }
		    }

		    return insert_index;
		}

		public void set_shader(Shader shader)
		    requires(shader != null)
		{
		    debug("set_shader: removing all buffers");
		    foreach (string buffer_name in _shader_buffers.get_keys())
		    {
		        remove_buffer(buffer_name, true);
		    }

            debug("set_shader: setting current shader to new one");
		    _curr_shader = new Shader();
		    _curr_shader.assign(shader);

		    debug(@"set_shader: the new shader is given by\n" +
		          @"$shader");

			for (int i = 0; i < shader.renderpasses.length; i++)
			{
				if (shader.renderpasses.index(i) is Shader.Renderpass)
				{
					Shader.Renderpass renderpass = shader.renderpasses.index(i) as Shader.Renderpass;

					debug(@"set_shader: adding renderpass $(renderpass.renderpass_name)");

                    if (renderpass.renderpass_name == "Image")
                    {
					    add_buffer(renderpass.renderpass_name, get_insert_index_for_buffer(renderpass.renderpass_name), false, true);
					}
					else
					{
					    SignalHandler.block(action_widget, change_renderpass_handler_id);
					    action_widget.set_buffer_active(renderpass.renderpass_name, true);
					    SignalHandler.unblock(action_widget, change_renderpass_handler_id);

					    add_buffer(renderpass.renderpass_name, get_insert_index_for_buffer(renderpass.renderpass_name), true, true);
					}

					set_buffer(renderpass.renderpass_name, renderpass.code);
				}
			}

            debug("set_shader: switching to buffer Image");
			switch_buffer("Image");

			do_full_char_count_refresh();

			// ensure the channel configuration has been set, even if the selected buffer was
			// already Image
			if (_channels_initialized)
            {
                debug("set_shader: channels are already initialized, so they will be updated now");
	            update_channels_for_current_shader();

	            for (int i = 0; i < _channels.length; i++)
			    {
			        _channels[i].channel_buffer = "Image";
			    }
	        }
		}

		private void change_renderpass(string buffer_name, bool active)
		{
		    if (active)
		    {
		        debug("change_renderpass: adding $buffer_name and setting default values for it");

		        string default_code = ShadertoyResourceManager.get_default_shader_by_buffer_name(buffer_name);

			    add_buffer(buffer_name, get_insert_index_for_buffer(buffer_name));
			    set_buffer(buffer_name, default_code);

                // TODO: the construction of these defaults should be moved elsewhere
			    Shader.Renderpass renderpass = new Shader.Renderpass();

			    renderpass.renderpass_name = buffer_name;
			    renderpass.code = default_code;

			    renderpass.type = Shader.RenderpassType.from_string(buffer_name);

			    Shader.Output output = new Shader.Output();

			    output.id = Shader.RENDERPASSES_ORDER[buffer_name];

			    renderpass.outputs.append_val(output);

			    _curr_shader.renderpasses.append_val(renderpass);
			}
			else
			{
			    debug("change_renderpass: removing $buffer_name");

			    remove_buffer(buffer_name);
			}
		}

        [GtkCallback]
		private void toggle_channels()
		{
		    channels_revealer.reveal_child = !channels_revealer.reveal_child;
		}

		private void channel_input_changed(Shader.Input channel_input)
		    requires(channel_input != null)
		{
			Shader.Renderpass? curr_renderpass = find_current_renderpass();
			if (curr_renderpass == null)
			{
			    warning("channel_input_changed: current renderpass is null");
				return;
			}

            for (int i = 0; i < curr_renderpass.inputs.length; i++)
		    {
		        int channel_index = curr_renderpass.inputs.index(i).channel;

		        if (channel_input.channel == channel_index)
		        {
		            debug("channel_input_changed: assigning new channel input to current renderpass");

			        curr_renderpass.inputs.index(i).assign(channel_input);
			        return;
			    }
			}

			curr_renderpass.inputs.append_val(channel_input);
		}

		[GtkCallback]
		private void switch_page(Gtk.Notebook sender_notebook, Gtk.Widget buffer, uint page_num)
		{
		    ShaderSourceBuffer old_buffer = _curr_buffer;
		    _curr_buffer = buffer as ShaderSourceBuffer;

            if (old_buffer != null)
            {
		        old_buffer.show_popovers = false;
		    }

		    _curr_buffer.show_popovers = true;

		    debug(@"switch_page: switching to $(_curr_buffer.buffer_name)");

		    //buffer_chars = _minifier.minify_kindly(_curr_buffer.buffer.text).length;
		    do_full_char_count_refresh();

            if (_channels_initialized)
            {
		        for (int i = 0; i < _channels.length; i++)
			    {
			        _channels[i].channel_buffer = _curr_buffer.buffer_name;
			    }
		    }

		    buffer_switched(old_buffer, buffer as ShaderSourceBuffer);
		}

		private void update_channels_for_current_shader()
		{
		    for (int i = 0; i < _channels.length; i++)
		    {
		        debug(@"update_channels_for_current_shader: setting channel content for channel $i");
		    	_channels[i].set_content_by_shader(_curr_shader);
		    }
		}
	}
}
