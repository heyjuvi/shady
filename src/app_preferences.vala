namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/app-preferences.ui")]
	public class AppPreferences : Gtk.Window
	{
		public enum GLSLVersion
		{
			GLSL_100_ES,
			GLSL_110,
			GLSL_120,
			GLSL_130,
			GLSL_140,
			GLSL_150,
			GLSL_300_ES,
			GLSL_330,
			GLSL_310_ES,
			GLSL_320_ES,
			GLSL_400,
			GLSL_410,
			GLSL_420,
			GLSL_430,
			GLSL_440,
			GLSL_450,
			GLSL_460,
			INVALID;

			public string to_string()
			{
				const string version_strings[17] = {"GLSL 1.00 ES (OpenGL ES 2.0) (WebGL 1.0)",
													"GLSL 1.10 (OpenGL 2.0)",
													"GLSL 1.20 (OpenGL 2.1)",
													"GLSL 1.30 (OpenGL 3.0)",
													"GLSL 1.40 (OpenGL 3.1)",
													"GLSL 1.50 (OpenGL 3.2)",
													"GLSL 3.00 ES (OpenGL ES 3.0) (WebGL 2.0)",
													"GLSL 3.30 (OpenGL 3.3)",
													"GLSL 3.10 ES (OpenGL ES 3.1)",
													"GLSL 3.20 ES (OpenGL ES 3.2)",
													"GLSL 4.00 (OpenGL 4.0)",
													"GLSL 4.10 (OpenGL 4.1)",
													"GLSL 4.20 (OpenGL 4.2)",
													"GLSL 4.30 (OpenGL 4.3)",
													"GLSL 4.40 (OpenGL 4.4)",
													"GLSL 4.50 (OpenGL 4.5)",
													"GLSL 4.60 (OpenGL 4.6)"};
				if(this < version_strings.length)
				{
					return version_strings[this];
				}
				else
				{
					return "INVALID GLSL VERSION";
				}
			}
			
			public string to_prefix_string()
			{
				const string version_prefix_array[17] = {"#version 100\n\n",
				                                         "#version 110\n\n",
				                                         "#version 120\n\n",
				                                         "#version 130\n\n",
				                                         "#version 140\n\n",
				                                         "#version 150\n\n",
				                                         "#version 300 es\n\n",
				                                         "#version 330\n\n",
				                                         "#version 310 es\n\n",
				                                         "#version 320 es\n\n",
				                                         "#version 400\n\n",
				                                         "#version 410\n\n",
				                                         "#version 420\n\n",
				                                         "#version 430\n\n",
				                                         "#version 440\n\n",
				                                         "#version 450\n\n",
				                                         "#version 460\n\n"};
				if(this < version_prefix_array.length)
				{
					return version_prefix_array[this];
				}
				else
				{
					return "";
				}
			}

			public string to_lang_name()
			{
				const string lang_names[17] = {"shadertoy_glsl_100es",
											   "shadertoy_glsl_110",
											   "shadertoy_glsl_120",
											   "shadertoy_glsl_130",
											   "shadertoy_glsl_140",
											   "shadertoy_glsl_150",
											   "shadertoy_glsl_300es",
											   "shadertoy_glsl_330",
											   "shadertoy_glsl_310es",
											   "shadertoy_glsl_320es",
											   "shadertoy_glsl_400",
											   "shadertoy_glsl_410",
											   "shadertoy_glsl_420",
											   "shadertoy_glsl_430",
											   "shadertoy_glsl_440",
											   "shadertoy_glsl_450",
											   "shadertoy_glsl_460"};

				if(this < lang_names.length)
				{
					return lang_names[this];
				}
				else
				{
					return "";
				}
			}
		}

		public enum BackportingMode
		{
			NONE,
			FULL,
			SHADERTOY;

			public string to_lang_suffix()
			{
				const string lang_suffixes[3] = {"",
				                                 "_full",
				                                 "_shadertoy"};

				if(this < lang_suffixes.length)
				{
					return lang_suffixes[this];
				}
				else
				{
					return "";
				}
			}
		}

		public bool switched_layout{ get; private set; default = false; }
		public bool auto_compile { get; private set; default = false; }
		public GLSLVersion glsl_version { get; private set; default = GLSL_300_ES; }
		public BackportingMode backporting_mode { get; private set; default = BackportingMode.NONE; }

		[Signal (action=true)]
		public signal void escape_pressed();

		[GtkChild]
		private Gtk.Switch switched_layout_switch;

		[GtkChild]
		private Gtk.Switch auto_compile_switch;

		[GtkChild]
		private Gtk.ListStore glsl_version_list;

		[GtkChild]
		private Gtk.ComboBoxText glsl_version_box;

		[GtkChild]
		private Gtk.Box backporting_box;

		[GtkChild]
		private Gtk.Label backporting_label;

		[GtkChild]
		private Gtk.RadioButton glsl_backporting_none;

		[GtkChild]
		private Gtk.RadioButton glsl_backporting_full;

		[GtkChild]
		private Gtk.RadioButton glsl_backporting_shadertoy;

		private GLib.Settings _settings;

		public AppPreferences()
		{
			_settings = new GLib.Settings("org.hasi.shady");

			escape_pressed.connect(() =>
			{
			    hide();
			});

			switched_layout = _settings.get_boolean("switched-layout");
			auto_compile = _settings.get_boolean("auto-compile");

			switched_layout_switch.set_state(switched_layout);
			auto_compile_switch.set_state(auto_compile);

			glsl_version = (GLSLVersion) _settings.get_enum("glsl-version");

			realize.connect(() =>
			{
				List<GLSLVersion> version_list = Core.ShaderCompiler.get_glsl_version_list(get_window());

				version_list.foreach((version) =>
				{
					Gtk.TreeIter iter;
					glsl_version_list.append(out iter);
					glsl_version_list.set(iter, 0, version.to_string(), 1, version);

					if(version == glsl_version)
					{
						glsl_version_box.set_active_iter(iter);
					}
				});
			});

			update_backporting_visibility();

			backporting_mode = (BackportingMode) _settings.get_enum("backporting");

			if(backporting_mode == BackportingMode.NONE)
			{
				glsl_backporting_none.set_active(true);
			}
			else if(backporting_mode == BackportingMode.FULL)
			{
				glsl_backporting_full.set_active(true);
			}
			else
			{
				glsl_backporting_shadertoy.set_active(true);
			}
		}

		private void update_backporting_visibility()
		{
			if(!(glsl_version < GLSLVersion.GLSL_150))
			{
				backporting_mode = BackportingMode.NONE;
				backporting_box.hide();
				backporting_label.hide();
			}
			else
			{
				backporting_box.show();
				backporting_label.show();
			}

			if(glsl_version == GLSLVersion.GLSL_100_ES)
			{
				glsl_backporting_shadertoy.sensitive = true;
			}
			else
			{
				glsl_backporting_shadertoy.sensitive = false;
			}
		}

		[GtkCallback]
		private bool switched_layout_switch_state_set(bool state)
		{
			_settings.set_boolean("switched-layout", state);

			return false;
		}

		[GtkCallback]
		private bool auto_compile_switch_state_set(bool state)
		{
			_settings.set_boolean("auto-compile", state);

			return false;
		}

		[GtkCallback]
		private void glsl_version_changed(Gtk.ComboBox box)
		{
			Gtk.TreeIter iter;
			box.get_active_iter(out iter);
			Value version;
			glsl_version_list.get_value(iter,1,out version);
			glsl_version = (GLSLVersion) version.get_int();
			_settings.set_enum("glsl-version", glsl_version);

			update_backporting_visibility();
		}

		[GtkCallback]
		private new bool hide_on_delete()
		{
			hide();

			return true;
		}

		[GtkCallback]
		private void backporting_none_toggled(Gtk.ToggleButton button)
		{
			backporting_mode = BackportingMode.NONE;
			_settings.set_enum("backporting", backporting_mode);
		}

		[GtkCallback]
		private void backporting_full_toggled(Gtk.ToggleButton button)
		{
			backporting_mode = BackportingMode.FULL;
			_settings.set_enum("backporting", backporting_mode);
		}

		[GtkCallback]
		private void backporting_shadertoy_toggled(Gtk.ToggleButton button)
		{
			backporting_mode = BackportingMode.SHADERTOY;
			_settings.set_enum("backporting", backporting_mode);
		}
	}
}
