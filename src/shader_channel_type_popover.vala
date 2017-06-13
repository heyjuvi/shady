namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel-type-popover.ui")]
	public class ShaderChannelTypePopover : Gtk.Popover
	{
		public signal void channel_type_changed(Shader.InputType channel_type);

		public ShaderChannelTypePopover()
		{
		}

		[GtkCallback]
		public void none_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.NONE);
			}
		}

		[GtkCallback]
		public void keyboard_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.KEYBOARD);
			}
		}

		[GtkCallback]
		public void webcam_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.WEBCAM);
			}
		}

		[GtkCallback]
		public void microphone_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.MICROPHONE);
			}
		}

		[GtkCallback]
		public void soundcloud_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.SOUNDCLOUD);
			}
		}

		[GtkCallback]
		public void buffer_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.BUFFER);
			}
		}

		[GtkCallback]
		public void texture_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.TEXTURE);
			}
		}

		[GtkCallback]
		public void cubemap_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.CUBEMAP);
			}
		}

		[GtkCallback]
		public void video_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.VIDEO);
			}
		}

		[GtkCallback]
		public void music_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.MUSIC);
			}
		}
	}
}
