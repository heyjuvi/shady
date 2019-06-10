namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel.ui")]
	public class ShaderChannel : Gtk.Box
	{
		private static Shader.Input TEXTURE_DEFAULT_INPUT = Shader.Input.NO_INPUT;
		private static Shader.Input CUBEMAP_DEFAULT_INPUT = Shader.Input.NO_INPUT;
		private static Shader.Input 3DTEXTURE_DEFAULT_INPUT = Shader.Input.NO_INPUT;
		private static Shader.Input BUFFER_DEFAULT_INPUT = ShaderChannelBufferPopover.generate_buffer_input("Buf A");

	    // TODO: can these be made obsolete by connecting to the property
	    //       signals directly?
		public signal void channel_type_changed(Shader.InputType channel_type);
		public signal void channel_input_changed(Shader.Input channel_input);

		public string channel_name
		{
			get { return name_label.get_text(); }
			set { name_label.set_text(value); }
		}

		private HashTable<string, Shader.Input> _last_texture_inputs = new HashTable<string, Shader.Input>(str_hash, str_equal);
		private HashTable<string, Shader.Input> _last_cubemap_inputs = new HashTable<string, Shader.Input>(str_hash, str_equal);
		private HashTable<string, Shader.Input> _last_3dtexture_inputs = new HashTable<string, Shader.Input>(str_hash, str_equal);
		private HashTable<string, Shader.Input> _last_buffer_inputs = new HashTable<string, Shader.Input>(str_hash, str_equal);

        private string _channel_buffer = "Image";
        public string channel_buffer
        {
            get { return _channel_buffer; }
            set
            {
                // needs to be set first, the following calls within the
                // channel_input property will make use of this
                _channel_buffer = value;

                channel_input = _channel_inputs[_channel_buffer];
            }
        }

        // TODO: setting the channel input is not safe until the widget has
        //       been realized, DANGER
		private HashTable<string, Shader.Input> _channel_inputs = new HashTable<string, Shader.Input>(str_hash, str_equal);
		public Shader.Input channel_input
		{
			get { return _channel_inputs[_channel_buffer]; }
			set
			{
				_channel_inputs[_channel_buffer].assign_content(value);

				if (_channel_inputs[_channel_buffer].sampler.filter == Shader.FilterMode.NEAREST)
				{
					filter_mode_combo_box.active = 0;
				}
				else if (_channel_inputs[_channel_buffer].sampler.filter == Shader.FilterMode.LINEAR)
				{
					filter_mode_combo_box.active = 1;
				}
				else if (_channel_inputs[_channel_buffer].sampler.filter == Shader.FilterMode.MIPMAP)
				{
					filter_mode_combo_box.active = 2;
				}

				if (_channel_inputs[_channel_buffer].sampler.wrap == Shader.WrapMode.CLAMP)
				{
					wrap_mode_combo_box.active = 0;
				}
				else if (_channel_inputs[_channel_buffer].sampler.wrap == Shader.WrapMode.REPEAT)
				{
					wrap_mode_combo_box.active = 1;
				}

				v_flip_switch.active = _channel_inputs[_channel_buffer].sampler.v_flip;

			    if (value.type == Shader.InputType.TEXTURE)
			    {
			        _last_texture_inputs[_channel_buffer].assign_content(_channel_inputs[_channel_buffer]);
			    }
			    else if (value.type == Shader.InputType.TEXTURE)
			    {
			        _last_cubemap_inputs[_channel_buffer].assign_content(_channel_inputs[_channel_buffer]);
			    }
			    else if (value.type == Shader.InputType.3DTEXTURE)
			    {
			        _last_3dtexture_inputs[_channel_buffer].assign_content(_channel_inputs[_channel_buffer]);
			    }
			    else if (value.type == Shader.InputType.BUFFER)
			    {
			        _last_buffer_inputs[_channel_buffer].assign_content(_channel_inputs[_channel_buffer]);
			    }

			    _channel_type_popover.set_channel_type_inconsistently(_channel_inputs[_channel_buffer].type);
			    update_for_input_type();
			    select_current_inputs();

			    debug(@"channel_input.set: channel input has been set to\n" +
			          @"$channel_input");

			    compile_input();
			}
		}

		public ChannelArea channel_area { get; private set; }

		[GtkChild]
		private Gtk.Label name_label;

		[GtkChild]
		private Gtk.Button value_button;

		[GtkChild]
		private Gtk.Box shader_container;

		[GtkChild]
		private Gtk.Revealer settings_revealer;

		[GtkChild]
		private Gtk.ComboBoxText filter_mode_combo_box;

		[GtkChild]
		private Gtk.ComboBoxText wrap_mode_combo_box;

		[GtkChild]
		private Gtk.Switch v_flip_switch;

		[GtkChild]
		private Gtk.MenuButton channel_type_button;

		private ShaderChannelTypePopover _channel_type_popover;

		private ShaderChannelSoundcloudPopover _soundcloud_popover;
		private ShaderChannelInputPopover _texture_popover;
		private ShaderChannelInputPopover _cubemap_popover;
		private ShaderChannelInputPopover _3dtexture_popover;
		private ShaderChannelBufferPopover _buffer_popover;

		private Gtk.Popover _current_popover;

		public ShaderChannel(int channel_id)
		{
			channel_area = new ChannelArea();

			shader_container.pack_start(channel_area, true, true);

            _channel_type_popover = new ShaderChannelTypePopover();
			_channel_type_popover.channel_type_changed.connect(channel_type_popover_channel_type_changed);
			_channel_type_popover.hide();

			channel_type_button.popover = _channel_type_popover;

			_soundcloud_popover = new ShaderChannelSoundcloudPopover(value_button);
			_texture_popover = new ShaderChannelInputPopover(Shader.InputType.TEXTURE, value_button);
			_cubemap_popover = new ShaderChannelInputPopover(Shader.InputType.CUBEMAP, value_button);
			_3dtexture_popover = new ShaderChannelInputPopover(Shader.InputType.3DTEXTURE, value_button);
			_buffer_popover = new ShaderChannelBufferPopover(value_button);

			_current_popover = null;

            // note the difference between a buffer, which correpsonds to a
            // notebook page in the editor and a buffer, which is actually
            // a renderpass and can be used as an input
			foreach (string buffer_name in Shader.RENDERPASSES_ORDER.get_keys())
            {
                _last_texture_inputs.insert(buffer_name, new Shader.Input());
                _last_texture_inputs[buffer_name].assign(TEXTURE_DEFAULT_INPUT);

                _last_cubemap_inputs.insert(buffer_name, new Shader.Input());
                _last_cubemap_inputs[buffer_name].assign(CUBEMAP_DEFAULT_INPUT);

                _last_3dtexture_inputs.insert(buffer_name, new Shader.Input());
                _last_3dtexture_inputs[buffer_name].assign(3DTEXTURE_DEFAULT_INPUT);

                _last_buffer_inputs.insert(buffer_name, new Shader.Input());
                _last_buffer_inputs[buffer_name].assign(BUFFER_DEFAULT_INPUT);

                _channel_inputs.insert(buffer_name, new Shader.Input());
            }

            foreach (string buffer_name in Shader.RENDERPASSES_ORDER.get_keys())
            {
                _channel_inputs[buffer_name].channel = channel_id;
            }

			_texture_popover.input_selected.connect((input) =>
			{
				_channel_inputs[_channel_buffer].assign_content(input);
				_last_texture_inputs[_channel_buffer].assign_content(input);

				update_for_input_type();
				read_sampler_to_input();
				compile_input();

				channel_input_changed(_channel_inputs[_channel_buffer]);
			});

			_cubemap_popover.input_selected.connect((input) =>
			{
				_channel_inputs[_channel_buffer].assign_content(input);
				_last_cubemap_inputs[_channel_buffer].assign_content(input);

				update_for_input_type();
				read_sampler_to_input();
				compile_input();

				channel_input_changed(_channel_inputs[_channel_buffer]);
			});

			_3dtexture_popover.input_selected.connect((input) =>
			{
				_channel_inputs[_channel_buffer].assign_content(input);
				_last_3dtexture_inputs[_channel_buffer].assign_content(input);

				update_for_input_type();
				read_sampler_to_input();
				compile_input();

				channel_input_changed(_channel_inputs[_channel_buffer]);
			});

			_buffer_popover.buffer_selected.connect((input) =>
			{
			    _channel_inputs[_channel_buffer].assign_content(input);
				_last_buffer_inputs[_channel_buffer].assign_content(input);

				update_for_input_type();
				read_sampler_to_input();
				compile_input();

				channel_input_changed(_channel_inputs[_channel_buffer]);
			});

			channel_area.show();
		}

		public void set_content_by_renderpass(Shader.Renderpass renderpass)
		{
			bool channel_in_use = false;

		    for (int i = 0; i < renderpass.inputs.length; i++)
		    {
		        int channel_index = renderpass.inputs.index(i).channel;
		        if (channel_index == channel_input.channel &&
		            renderpass.name in Shader.RENDERPASSES_ORDER.get_keys().data)
		        {
 		            debug(@"set_content_by_shader: setting assigning channel input for channel $(channel_input.channel)\n" +
	                      @"$(renderpass.inputs.index(i))");

		            _channel_inputs[renderpass.name].assign_content(renderpass.inputs.index(i));

				    if (_channel_inputs[renderpass.name].type == Shader.InputType.TEXTURE)
				    {
				        _last_texture_inputs[_channel_buffer].assign_content(_channel_inputs[_channel_buffer]);
				    }
				    else if (_channel_inputs[renderpass.name].type == Shader.InputType.TEXTURE)
				    {
				        _last_cubemap_inputs[_channel_buffer].assign_content(_channel_inputs[_channel_buffer]);
				    }
				    else if (_channel_inputs[renderpass.name].type == Shader.InputType.3DTEXTURE)
				    {
				        _last_3dtexture_inputs[_channel_buffer].assign_content(_channel_inputs[_channel_buffer]);
				    }
				    else if (_channel_inputs[renderpass.name].type == Shader.InputType.BUFFER)
				    {
				        _last_buffer_inputs[_channel_buffer].assign_content(_channel_inputs[_channel_buffer]);
				    }

		            channel_in_use = true;
		        }
		    }

    		/*if (!channel_in_use)
    		{
    			channel_input = Shader.Input.NO_INPUT;
    		}*/

    		if (renderpass.name == _channel_buffer)
    		{
    		    _channel_type_popover.set_channel_type_inconsistently(_channel_inputs[_channel_buffer].type);
			    update_for_input_type();
			    select_current_inputs();
    		}
		}

		public void set_content_by_shader(Shader shader)
		{
			for (int i = 0; i < shader.renderpasses.length; i++)
			{
			    set_content_by_renderpass(shader.renderpasses.index(i));
		    }
		}

		private void read_sampler_to_input()
		{
			_channel_inputs[_channel_buffer].sampler.filter = Shader.FilterMode.from_string(filter_mode_combo_box.get_active_text());
			_channel_inputs[_channel_buffer].sampler.wrap = Shader.WrapMode.from_string(wrap_mode_combo_box.get_active_text());
			_channel_inputs[_channel_buffer].sampler.v_flip = v_flip_switch.active;
		}

		private void update_for_input_type()
		{
			if (_channel_inputs[_channel_buffer].type == Shader.InputType.SOUNDCLOUD ||
			    _channel_inputs[_channel_buffer].type == Shader.InputType.BUFFER ||
			    _channel_inputs[_channel_buffer].type == Shader.InputType.TEXTURE ||
			    _channel_inputs[_channel_buffer].type == Shader.InputType.3DTEXTURE ||
			    _channel_inputs[_channel_buffer].type == Shader.InputType.CUBEMAP ||
			    _channel_inputs[_channel_buffer].type == Shader.InputType.VIDEO ||
			    _channel_inputs[_channel_buffer].type == Shader.InputType.MUSIC)
			{
				value_button.visible = true;

				if (_channel_inputs[_channel_buffer].type == Shader.InputType.SOUNDCLOUD)
				{
					_soundcloud_popover.popdown();
					_current_popover = _soundcloud_popover;
				}
				else if (_channel_inputs[_channel_buffer].type == Shader.InputType.TEXTURE)
				{
					_texture_popover.popdown();
					_current_popover = _texture_popover;
					_channel_inputs[_channel_buffer].assign_content(_last_texture_inputs[_channel_buffer]);
				}
				else if (_channel_inputs[_channel_buffer].type == Shader.InputType.CUBEMAP)
				{
					_cubemap_popover.popdown();
					_current_popover = _cubemap_popover;
					_channel_inputs[_channel_buffer].assign_content(_last_cubemap_inputs[_channel_buffer]);
				}
				else if (_channel_inputs[_channel_buffer].type == Shader.InputType.3DTEXTURE)
				{
					_3dtexture_popover.popdown();
					_current_popover = _3dtexture_popover;
					_channel_inputs[_channel_buffer].assign_content(_last_3dtexture_inputs[_channel_buffer]);
				}
				else if (_channel_inputs[_channel_buffer].type == Shader.InputType.BUFFER)
				{
				    _buffer_popover.popdown();
				    _current_popover = _buffer_popover;
				    _channel_inputs[_channel_buffer].assign_content(_last_buffer_inputs[_channel_buffer]);
				}
			}
			else
			{
				value_button.visible = false;
			}
		}

		private void select_current_inputs()
		{
			if (_channel_inputs[_channel_buffer].type == Shader.InputType.BUFFER ||
			    _channel_inputs[_channel_buffer].type == Shader.InputType.TEXTURE ||
			    _channel_inputs[_channel_buffer].type == Shader.InputType.3DTEXTURE ||
			    _channel_inputs[_channel_buffer].type == Shader.InputType.CUBEMAP ||
			    _channel_inputs[_channel_buffer].type == Shader.InputType.VIDEO ||
			    _channel_inputs[_channel_buffer].type == Shader.InputType.MUSIC)
			{
				if (_channel_inputs[_channel_buffer].type == Shader.InputType.SOUNDCLOUD)
				{
				}
				else if (_channel_inputs[_channel_buffer].type == Shader.InputType.TEXTURE)
				{
				}
				else if (_channel_inputs[_channel_buffer].type == Shader.InputType.CUBEMAP)
				{
				}
				else if (_channel_inputs[_channel_buffer].type == Shader.InputType.3DTEXTURE)
				{
				}
				else if (_channel_inputs[_channel_buffer].type == Shader.InputType.BUFFER)
				{
					string buffer = null;
					foreach (string buffer_name in Shader.RENDERPASSES_ORDER.get_keys())
					{
						if (Shader.RENDERPASSES_ORDER[buffer_name] == _channel_inputs[_channel_buffer].id)
						{
							buffer = buffer_name;
							break;
						}
					}

					if (buffer != null)
					{
						print(@"shader_channel@select_current_inputs: setting buffer_name to $buffer\n");
						//_buffer_popover.buffer_name = buffer;
						_buffer_popover.set_buffer_name_inconsistently(buffer);
					}
				}
			}
		}

		private void compile_input()
		{
			channel_area.compile_shader_input(_channel_inputs[_channel_buffer]);
		}

		private void channel_type_popover_channel_type_changed(Shader.InputType channel_type)
		{
			_channel_inputs[_channel_buffer].type = channel_type;

			update_for_input_type();
			select_current_inputs();

			compile_input();

			channel_type_changed(_channel_inputs[_channel_buffer].type);
			channel_input_changed(_channel_inputs[_channel_buffer]);
		}

		[GtkCallback]
		private void value_button_clicked()
		{
			_current_popover.popup();
		}

		[GtkCallback]
		private void settings_button_toggled(Gtk.ToggleButton button)
		{
			settings_revealer.set_reveal_child(button.active);
		}

		[GtkCallback]
		private void filter_mode_combo_box_changed()
		{
			read_sampler_to_input();
			compile_input();

			channel_input_changed(_channel_inputs[_channel_buffer]);
		}

		[GtkCallback]
		private void wrap_mode_combo_box_changed()
		{
			read_sampler_to_input();
			compile_input();

			channel_input_changed(_channel_inputs[_channel_buffer]);
		}

		[GtkCallback]
		private void v_flip_switch_toggled()
		{
			read_sampler_to_input();
			compile_input();

			channel_input_changed(_channel_inputs[_channel_buffer]);
		}
	}
}
