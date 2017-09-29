namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel.ui")]
	public class ShaderChannel : Gtk.Box
	{
		public signal void channel_type_changed(Shader.InputType channel_type);
		public signal void channel_input_changed(Shader.Input channel_input);

		public Shader.InputType channel_type { get; set; default = Shader.InputType.NONE; }

		public string channel_name
		{
			get { return name_label.get_text(); }
			set { name_label.set_text(value); }
		}

		private Shader.Input _channel_input = new Shader.Input();
		public Shader.Input channel_input
		{
			get { return _channel_input; }
			set
			{
				_channel_input = value;

				if (_channel_input.sampler.filter == Shader.FilterMode.NEAREST)
				{
					filter_mode_combo_box.active = 0;
				}
				else if (_channel_input.sampler.filter == Shader.FilterMode.LINEAR)
				{
					filter_mode_combo_box.active = 1;
				}
				else if (_channel_input.sampler.filter == Shader.FilterMode.MIPMAP)
				{
					filter_mode_combo_box.active = 2;
				}

				if (_channel_input.sampler.wrap == Shader.WrapMode.CLAMP)
				{
					wrap_mode_combo_box.active = 0;
				}
				else if (_channel_input.sampler.wrap == Shader.WrapMode.REPEAT)
				{
					wrap_mode_combo_box.active = 1;
				}

				v_flip_switch.active = _channel_input.sampler.v_flip;

				update_type();
				update_shader();
			}
		}

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

		private ShaderChannelSoundcloudPopover _soundcloud_popover;
		private ShaderChannelInputPopover _texture_popover;
		private ShaderChannelInputPopover _cubemap_popover;
		private ShaderChannelInputPopover _3dtexture_popover;

		private Gtk.Popover _current_popover;

		private ShaderArea _shader_area;

		public ShaderChannel()
		{
			_shader_area = new ShaderArea();

			shader_container.pack_start(_shader_area, true, true);

			_soundcloud_popover = new ShaderChannelSoundcloudPopover(value_button);
			_texture_popover = new ShaderChannelInputPopover(Shader.InputType.TEXTURE, value_button);
			_cubemap_popover = new ShaderChannelInputPopover(Shader.InputType.CUBEMAP, value_button);
			_3dtexture_popover = new ShaderChannelInputPopover(Shader.InputType.3DTEXTURE, value_button);

			_current_popover = _texture_popover;

			_texture_popover.input_selected.connect((input) =>
			{
				_channel_input = input;

				update_type();
				update_sampler();
				update_shader();

				channel_input_changed(_channel_input);
			});

			_cubemap_popover.input_selected.connect((input) =>
			{
				_channel_input = input;

				update_type();
				update_sampler();
				update_shader();

				channel_input_changed(_channel_input);
			});

			_3dtexture_popover.input_selected.connect((input) =>
			{
				_channel_input = input;

				update_type();
				update_sampler();
				update_shader();

				channel_input_changed(_channel_input);
			});

			_shader_area.show();

			_shader_area.initialized.connect(() =>
			{
				_shader_area.compile_default_shader_no_thread();
			});
		}

		private void update_sampler()
		{
			channel_input.sampler.filter = Shader.FilterMode.from_string(filter_mode_combo_box.get_active_text());
			channel_input.sampler.wrap = Shader.WrapMode.from_string(wrap_mode_combo_box.get_active_text());
			channel_input.sampler.v_flip = v_flip_switch.active;
		}

		private void update_type()
		{
			if (_channel_input.type == Shader.InputType.SOUNDCLOUD ||
			    _channel_input.type == Shader.InputType.BUFFER ||
			    _channel_input.type == Shader.InputType.TEXTURE ||
			    _channel_input.type == Shader.InputType.3DTEXTURE ||
			    _channel_input.type == Shader.InputType.CUBEMAP ||
			    _channel_input.type == Shader.InputType.VIDEO ||
			    _channel_input.type == Shader.InputType.MUSIC)
			{
				value_button.visible = true;

				if (_channel_input.type == Shader.InputType.SOUNDCLOUD)
				{
					_soundcloud_popover.hide();
					_current_popover = _soundcloud_popover;
				}
				else if (_channel_input.type == Shader.InputType.TEXTURE)
				{
					_texture_popover.hide();
					_current_popover = _texture_popover;
				}
				else if (_channel_input.type == Shader.InputType.CUBEMAP)
				{
					_cubemap_popover.hide();
					_current_popover = _cubemap_popover;
				}
				else if (_channel_input.type == Shader.InputType.3DTEXTURE)
				{
					_3dtexture_popover.hide();
					_current_popover = _3dtexture_popover;
				}
			}
			else
			{
				value_button.visible = false;
			}
		}

		private void update_shader()
		{
			_shader_area.compile_shader_input(_channel_input);
		}

		[GtkCallback]
		private void channel_type_popover_channel_type_changed(Shader.InputType channel_type)
		{
			_channel_input.type = channel_type;

			update_type();
			update_shader();

			channel_type_changed(_channel_input.type);
			channel_input_changed(_channel_input);
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
			update_sampler();

			channel_input_changed(_channel_input);
		}

		[GtkCallback]
		private void wrap_mode_combo_box_changed()
		{
			update_sampler();

			channel_input_changed(_channel_input);
		}

		[GtkCallback]
		private void v_flip_switch_toggled()
		{
			update_sampler();

			channel_input_changed(_channel_input);
		}
	}
}
