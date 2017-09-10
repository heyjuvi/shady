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
		private Gtk.MenuButton value_button;

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

		private ShaderChannelSoundcloudPopover _soundcloud_popover = new ShaderChannelSoundcloudPopover();
		private ShaderChannelTexturePopover _texture_popover = new ShaderChannelTexturePopover();

		private ShaderArea _shader_area;

		public ShaderChannel()
		{
			// for some reason the shader area must not be constructed in a ui
			// file
			Shader default_shader = new Shader();
			Shader.Renderpass renderpass = new Shader.Renderpass();

			try
			{
				string default_code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/default.glsl", 0).get_data());
				renderpass.code = default_code;
			}
			catch (Error e)
			{
				print("Couldn't load default shader\n");
			}

			renderpass.type = Shader.RenderpassType.IMAGE;

			default_shader.renderpasses.append_val(renderpass);
			_shader_area = new ShaderArea(default_shader);

			shader_container.pack_start(_shader_area, true, true);

			_texture_popover.texture_selected.connect((texture_id) =>
			{
				_channel_input = ShadertoyResourceManager.TEXTURES[texture_id];

				update_type();
				update_sampler();
				update_shader();

				channel_input_changed(_channel_input);
			});

			_shader_area.show();
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
			    _channel_input.type == Shader.InputType.CUBEMAP ||
			    _channel_input.type == Shader.InputType.VIDEO ||
			    _channel_input.type == Shader.InputType.MUSIC)
			{
				value_button.visible = true;

				if (_channel_input.type == Shader.InputType.SOUNDCLOUD)
				{
					_soundcloud_popover.hide();
					value_button.popover = _soundcloud_popover;
				}
				else if (_channel_input.type == Shader.InputType.TEXTURE)
				{
					_texture_popover.hide();
					value_button.popover = _texture_popover;
				}
			}
			else
			{
				value_button.visible = false;
			}
		}

		private void update_shader()
		{
			if (_channel_input.resource == null)
			{
				print("BUT WHY???\n\n\n\n");
				return;
			}

			if (_channel_input.type == Shader.InputType.TEXTURE)
			{
				Shader.Renderpass texture_renderpass = new Shader.Renderpass();
				texture_renderpass.type = Shader.RenderpassType.IMAGE;

				try
				{
					texture_renderpass.code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/texture_channel_default.glsl", 0).get_data());
				}
				catch (Error e)
				{
					print("Couldn't load texture channel default shader\n");
				}

				texture_renderpass.inputs.append_val(_channel_input);

				Shader texture_shader = new Shader();
				texture_shader.renderpasses.append_val(texture_renderpass);

				_shader_area.compile_no_thread(texture_shader);
			}
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
