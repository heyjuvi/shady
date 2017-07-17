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
				popdown();
			}
		}

		[GtkCallback]
		public void keyboard_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.KEYBOARD);
				popdown();
			}
		}

		[GtkCallback]
		public void webcam_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.WEBCAM);
				popdown();
			}
		}

		[GtkCallback]
		public void microphone_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.MICROPHONE);
				popdown();
			}
		}

		[GtkCallback]
		public void soundcloud_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.SOUNDCLOUD);
				popdown();
			}
		}

		[GtkCallback]
		public void buffer_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.BUFFER);
				popdown();
			}
		}

		[GtkCallback]
		public void texture_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.TEXTURE);
				popdown();
			}
		}

		[GtkCallback]
		public void cubemap_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.CUBEMAP);
				popdown();
			}
		}

		[GtkCallback]
		public void video_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.VIDEO);
				popdown();
			}
		}

		[GtkCallback]
		public void music_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.MUSIC);
				popdown();
			}
		}
	}
}
