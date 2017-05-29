namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel-type-popover.ui")]
	public class ShaderChannelTypePopover : Gtk.Popover
	{
		public signal void channel_type_changed(ShaderChannel.ChannelType channel_type);

		public ShaderChannelTypePopover()
		{
		}

		[GtkCallback]
		public void none_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(ShaderChannel.ChannelType.NONE);
			}
		}

		[GtkCallback]
		public void keyboard_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(ShaderChannel.ChannelType.KEYBOARD);
			}
		}

		[GtkCallback]
		public void webcam_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(ShaderChannel.ChannelType.WEBCAM);
			}
		}

		[GtkCallback]
		public void microphone_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(ShaderChannel.ChannelType.MICROPHONE);
			}
		}

		[GtkCallback]
		public void soundcloud_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(ShaderChannel.ChannelType.SOUNDCLOUD);
			}
		}

		[GtkCallback]
		public void buffer_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(ShaderChannel.ChannelType.BUFFER);
			}
		}

		[GtkCallback]
		public void texture_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(ShaderChannel.ChannelType.TEXTURE);
			}
		}

		[GtkCallback]
		public void cubemap_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(ShaderChannel.ChannelType.CUBEMAP);
			}
		}

		[GtkCallback]
		public void video_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(ShaderChannel.ChannelType.VIDEO);
			}
		}

		[GtkCallback]
		public void music_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(ShaderChannel.ChannelType.MUSIC);
			}
		}
	}
}
