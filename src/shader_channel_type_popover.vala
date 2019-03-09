namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel-type-popover.ui")]
	public class ShaderChannelTypePopover : Gtk.Popover
	{
		public signal void channel_type_changed(Shader.InputType channel_type);

		private Shader.InputType _channel_type = Shader.InputType.NONE;
		public Shader.InputType channel_type
		{
		    get { return _channel_type; }
		    set
		    {
		        if (value == Shader.InputType.NONE)
		        {
		            none_radio_button.active = true;
		        }
		        else if (value == Shader.InputType.KEYBOARD)
			    {
			        keyboard_radio_button.active = true;
			    }
			    else if (value == Shader.InputType.WEBCAM)
			    {
			        webcam_radio_button.active = true;
			    }
			    else if (value == Shader.InputType.MICROPHONE)
			    {
			        microphone_radio_button.active = true;
			    }
			    else if (value == Shader.InputType.SOUNDCLOUD)
			    {
			        soundcloud_radio_button.active = true;
			    }
			    else if (value == Shader.InputType.BUFFER)
			    {
			        buffer_radio_button.active = true;
			    }
			    else if (value == Shader.InputType.TEXTURE)
			    {
			        texture_radio_button.active = true;
			    }
			    else if (value == Shader.InputType.3DTEXTURE)
			    {
			        _3dtexture_radio_button.active = true;
			    }
			    else if (value == Shader.InputType.CUBEMAP)
			    {
			        cubemap_radio_button.active = true;
			    }
			    else if (value == Shader.InputType.VIDEO)
			    {
			        video_radio_button.active = true;
			    }
			    else if (value == Shader.InputType.MUSIC)
			    {
			        music_radio_button.active = true;
			    }

		        _channel_type = value;
		    }
		}

		[GtkChild]
		private Gtk.RadioButton none_radio_button;

		[GtkChild]
		private Gtk.RadioButton keyboard_radio_button;

		[GtkChild]
		private Gtk.RadioButton webcam_radio_button;

		[GtkChild]
		private Gtk.RadioButton microphone_radio_button;

		[GtkChild]
		private Gtk.RadioButton soundcloud_radio_button;

		[GtkChild]
		private Gtk.RadioButton buffer_radio_button;

		[GtkChild]
		private Gtk.RadioButton texture_radio_button;

		[GtkChild]
		private Gtk.RadioButton _3dtexture_radio_button;

		[GtkChild]
		private Gtk.RadioButton cubemap_radio_button;

		[GtkChild]
		private Gtk.RadioButton video_radio_button;

		[GtkChild]
		private Gtk.RadioButton music_radio_button;

		private ulong none_radio_button_handler_id = 0;
	    private ulong keyboard_radio_button_handler_id = 0;
	    private ulong webcam_radio_button_handler_id = 0;
	    private ulong microphone_radio_button_handler_id = 0;
	    private ulong soundcloud_radio_button_handler_id = 0;
	    private ulong buffer_radio_button_handler_id = 0;
	    private ulong texture_radio_button_handler_id = 0;
	    private ulong cubemap_radio_button_handler_id = 0;
	    private ulong _3dtexture_radio_button_handler_id = 0;
	    private ulong video_radio_button_handler_id = 0;
	    private ulong music_radio_button_handler_id = 0;

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
		    none_radio_button_handler_id = none_radio_button.toggled.connect(none_radio_button_toggled);
		    keyboard_radio_button_handler_id = keyboard_radio_button.toggled.connect(keyboard_radio_button_toggled);
		    webcam_radio_button_handler_id = webcam_radio_button.toggled.connect(webcam_radio_button_toggled);
		    microphone_radio_button_handler_id = microphone_radio_button.toggled.connect(microphone_radio_button_toggled);
		    soundcloud_radio_button_handler_id = soundcloud_radio_button.toggled.connect(soundcloud_radio_button_toggled);
		    buffer_radio_button_handler_id = buffer_radio_button.toggled.connect(buffer_radio_button_toggled);
		    texture_radio_button_handler_id = texture_radio_button.toggled.connect(texture_radio_button_toggled);
		    cubemap_radio_button_handler_id = cubemap_radio_button.toggled.connect(cubemap_radio_button_toggled);
		    _3dtexture_radio_button_handler_id = _3dtexture_radio_button.toggled.connect(3dtexture_radio_button_toggled);
		    video_radio_button_handler_id = video_radio_button.toggled.connect(video_radio_button_toggled);
		    music_radio_button_handler_id = music_radio_button.toggled.connect(music_radio_button_toggled);
		}

		public void set_channel_type_inconsistently(Shader.InputType new_channel_type)
		{
		    SignalHandler.block(none_radio_button, none_radio_button_handler_id);
		    SignalHandler.block(keyboard_radio_button, keyboard_radio_button_handler_id);
		    SignalHandler.block(webcam_radio_button, webcam_radio_button_handler_id);
		    SignalHandler.block(microphone_radio_button, microphone_radio_button_handler_id);
		    SignalHandler.block(soundcloud_radio_button, soundcloud_radio_button_handler_id);
		    SignalHandler.block(buffer_radio_button, buffer_radio_button_handler_id);
		    SignalHandler.block(texture_radio_button, texture_radio_button_handler_id);
		    SignalHandler.block(cubemap_radio_button, cubemap_radio_button_handler_id);
		    SignalHandler.block(_3dtexture_radio_button, _3dtexture_radio_button_handler_id);
		    SignalHandler.block(video_radio_button, video_radio_button_handler_id);
		    SignalHandler.block(music_radio_button, music_radio_button_handler_id);

		    channel_type = new_channel_type;

		    SignalHandler.unblock(none_radio_button, none_radio_button_handler_id);
		    SignalHandler.unblock(keyboard_radio_button, keyboard_radio_button_handler_id);
		    SignalHandler.unblock(webcam_radio_button, webcam_radio_button_handler_id);
		    SignalHandler.unblock(microphone_radio_button, microphone_radio_button_handler_id);
		    SignalHandler.unblock(soundcloud_radio_button, soundcloud_radio_button_handler_id);
		    SignalHandler.unblock(buffer_radio_button, buffer_radio_button_handler_id);
		    SignalHandler.unblock(texture_radio_button, texture_radio_button_handler_id);
		    SignalHandler.unblock(cubemap_radio_button, cubemap_radio_button_handler_id);
		    SignalHandler.unblock(_3dtexture_radio_button, _3dtexture_radio_button_handler_id);
		    SignalHandler.unblock(video_radio_button, video_radio_button_handler_id);
		    SignalHandler.unblock(music_radio_button, music_radio_button_handler_id);
		}

		public void none_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.NONE);
				popdown();
			}
		}

		public void keyboard_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.KEYBOARD);
				popdown();
			}
		}

		public void webcam_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.WEBCAM);
				popdown();
			}
		}

		public void microphone_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.MICROPHONE);
				popdown();
			}
		}

		public void soundcloud_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.SOUNDCLOUD);
				popdown();
			}
		}

		public void buffer_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.BUFFER);
				popdown();
			}
		}

		public void texture_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.TEXTURE);
				popdown();
			}
		}

		public void cubemap_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.CUBEMAP);
				popdown();
			}
		}

		public void 3dtexture_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.3DTEXTURE);
				popdown();
			}
		}

		public void video_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				channel_type_changed(Shader.InputType.VIDEO);
				popdown();
			}
		}

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
