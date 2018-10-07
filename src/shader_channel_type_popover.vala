namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel-type-popover.ui")]
	public class ShaderChannelTypePopover : Gtk.Popover
	{
		public signal void channel_type_changed(Shader.InputType channel_type);

		[GtkChild]
		private Gtk.RadioButton _3dtexture_radio_button;

		[GtkChild]
		private Gtk.RadioButton none_radio_button;

		private GLib.Settings _settings = new GLib.Settings("org.hasi.shady");

		construct
		{
		    _settings.changed["glsl-version"].connect(() =>
	        {
	            AppPreferences.GLSLVersion glsl_version = (AppPreferences.GLSLVersion) _settings.get_enum("glsl-version");

	            if (glsl_version == AppPreferences.GLSLVersion.GLSL_100_ES)
	            {
	                _3dtexture_radio_button.visible = false;
	                none_radio_button.active = true;
	            }
	            else
	            {
	                _3dtexture_radio_button.visible = true;
	            }
	        });

            AppPreferences.GLSLVersion glsl_version = (AppPreferences.GLSLVersion) _settings.get_enum("glsl-version");

	        if (glsl_version == AppPreferences.GLSLVersion.GLSL_100_ES)
            {
                _3dtexture_radio_button.visible = false;
                none_radio_button.active = true;
            }
            else
            {
                _3dtexture_radio_button.visible = true;
            }
		}

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
		public void 3dtexture_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.3DTEXTURE);
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
