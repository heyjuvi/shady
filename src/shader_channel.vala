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

		[GtkChild]
		private Gtk.Label name_label;

		[GtkChild]
		private Gtk.MenuButton value_button;

		[GtkChild]
		private Gtk.Stack content_stack;

		[GtkChild]
		private Gtk.Box shader_container;

		private ShaderChannelSoundcloudPopover _soundcloud_popover = new ShaderChannelSoundcloudPopover();
		private ShaderChannelTexturePopover _texture_popover = new ShaderChannelTexturePopover();

		private ShaderArea _shader_area;

		public ShaderChannel()
		{
			// for some reason the shader area must not be constructed in a ui
			// file
			Shader default_shader = new Shader();
			Shader.Renderpass renderpass = new Shader.Renderpass();

			try{
				string default_code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/default.glsl", 0).get_data());
				renderpass.code = default_code;
			}
			catch(Error e){
				print("Couldn't load default shader \n");
			}
			renderpass.type = Shader.RenderpassType.IMAGE;

			default_shader.renderpasses.append_val(renderpass);
			_shader_area = new ShaderArea(default_shader);

			shader_container.pack_start(_shader_area, true, true);

			_texture_popover.texture_selected.connect((texture_input) =>
			{
				Shader.Renderpass texture_renderpass = new Shader.Renderpass();
				texture_renderpass.type = Shader.RenderpassType.IMAGE;
				try{
					texture_renderpass.code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/texture_channel_default.glsl", 0).get_data());
				}
				catch(Error e){
					print("Couldn't load texture channel default shader\n");
				}
				texture_renderpass.inputs.append_val(texture_input);

				Shader texture_shader = new Shader();
				texture_shader.renderpasses.append_val(texture_renderpass);

				_shader_area.compile_no_thread(texture_shader);

				channel_input_changed(texture_input);
			});

			_shader_area.show();
		}

		[GtkCallback]
		private void channel_type_popover_channel_type_changed(Shader.InputType channel_type)
		{
			if (channel_type == Shader.InputType.SOUNDCLOUD ||
			    channel_type == Shader.InputType.BUFFER ||
			    channel_type == Shader.InputType.TEXTURE ||
			    channel_type == Shader.InputType.CUBEMAP ||
			    channel_type == Shader.InputType.VIDEO ||
			    channel_type == Shader.InputType.MUSIC)
			{
				value_button.visible = true;

				if (channel_type == Shader.InputType.SOUNDCLOUD)
				{
					_soundcloud_popover.hide();
					value_button.popover = _soundcloud_popover;
				}
				else if (channel_type == Shader.InputType.TEXTURE)
				{
					_texture_popover.hide();
					value_button.popover = _texture_popover;
				}
			}
			else
			{
				value_button.visible = false;
			}

			channel_type_changed(channel_type);
		}

		[GtkCallback]
		private void settings_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				content_stack.visible_child_name = "settings_stack";
			}
			else
			{
				content_stack.visible_child_name = "shader_container";
			}
		}
	}
}
