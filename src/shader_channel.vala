namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel.ui")]
	public class ShaderChannel : Gtk.Box
	{
		public enum ChannelType
		{
			NONE,
			KEYBOARD,
			WEBCAM,
			MICROPHONE,
			SOUNDCLOUD,
			BUFFER,
			TEXTURE,
			CUBEMAP,
			VIDEO,
			MUSIC
		}

		public ChannelType channel_type { get; set; default = ChannelType.NONE; }

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

		private ShaderChannelTexturePopover _texture_popover = new ShaderChannelTexturePopover();

		private ShaderArea _shader_area;

		public ShaderChannel()
		{
			// for some reason the shader area must not be constructed in a ui
			// file
			_shader_area = new ShaderArea((string) (resources_lookup_data("/org/hasi/shady/data/shader/default.glsl", 0).get_data()));

			shader_container.pack_start(_shader_area, true, true);

			_shader_area.show();
		}

		[GtkCallback]
		private void channel_type_popover_channel_type_changed(ChannelType channel_type)
		{
			if (channel_type == ChannelType.SOUNDCLOUD ||
			    channel_type == ChannelType.BUFFER ||
			    channel_type == ChannelType.TEXTURE ||
			    channel_type == ChannelType.CUBEMAP ||
			    channel_type == ChannelType.VIDEO ||
			    channel_type == ChannelType.MUSIC)
			{
				value_button.visible = true;

				if (channel_type == ChannelType.TEXTURE)
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
