using GL;
using Gtk;
using Pango;

namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/app-window.ui")]
	public class AppWindow : Gtk.ApplicationWindow
	{
		private bool _edited;
		public bool edited
		{
			get { return _edited; }
			default = false;
		}

		private bool _switched_layout = false;
		public bool switched_layout
		{
			get { return _switched_layout; }
			set
			{
				if (value != _switched_layout)
				{
					main_paned.remove(_editor);
			        main_paned.remove(_scene);

			        if (value)
			        {
				        main_paned.pack1(_scene, true, true);
				        main_paned.pack2(_editor, true, true);
			        }
			        else
			        {
				        main_paned.pack1(_editor, true, true);
				        main_paned.pack2(_scene, true, true);
			        }

			        compile();

			        _switched_layout = value;
				}
			}
		}

		[GtkChild]
		private Gtk.MenuButton menu_button;

		[GtkChild]
		private Gtk.Image play_button_image;

		[GtkChild]
		private Gtk.Revealer rubber_band_revealer;

		[GtkChild]
		private Gtk.Scale rubber_band_scale;

		[GtkChild]
		private Gtk.Stack compile_button_stack;
		[GtkChild]
		private Gtk.Button compile_button;

		[GtkChild]
		private Gtk.Paned main_paned;

        private ShaderScene _scene;
		private ShaderEditor _editor;

		private GLib.Settings _settings = new GLib.Settings("org.hasi.shady");

		private uint _auto_compile_handler_id;

		public AppWindow(Gtk.Application app, AppPreferences preferences)
		{
			Object(application: app);

            _scene = new ShaderScene();
			_editor = new ShaderEditor();

			// set current switched layout state
			_switched_layout = _settings.get_boolean("switched-layout");

			if (_switched_layout)
			{
				main_paned.pack1(_scene, true, true);
				main_paned.pack2(_editor, true, true);
			}
			else
			{
				main_paned.pack1(_editor, true, true);
				main_paned.pack2(_scene, true, true);
			}

			if (!app.prefers_app_menu())
			{
				menu_button.menu_model = app.app_menu;
				menu_button.visible = true;
			}

			key_press_event.connect((widget, event) =>
			{
				/*bool is_fullscreen = (get_window().get_state() & Gdk.WindowState.FULLSCREEN) == Gdk.WindowState.FULLSCREEN;

				if (event.keyval == Gdk.Key.F11)
				{
					if (is_fullscreen)
					{
						leave_fullscreen(_scene.shader_manager);
					}
					else
					{
						enter_fullscreen(_scene.shader_manager);
					}
				}

				if (is_fullscreen && event.keyval == Gdk.Key.Escape)
				{
					leave_fullscreen(_scene.shader_manager);
				}*/

				return false;
			});

			/*window_state_event.connect((event) =>
			{
				bool is_fullscreen = (get_window().get_state() & Gdk.WindowState.FULLSCREEN) == Gdk.WindowState.FULLSCREEN;

				_editor.visible = !is_fullscreen;

				return false;
			});*/

			// react to changed editor layout
			_settings.changed["switched-layout"].connect(switched_layout_handler);

			// compile every 5 seconds, if auto compile is enabled
			_auto_compile_handler_id = Timeout.add(3000, auto_compile_handler, Priority.HIGH_IDLE);
		}

		[GtkCallback]
		private void on_destroy()
		{
			// remove all handler
			_settings.changed["switched-layout"].disconnect(switched_layout_handler);
			Source.remove(_auto_compile_handler_id);
		}

		private bool auto_compile_handler()
		{
			if (_settings.get_boolean("auto-compile"))
			{
				compile();
			}

			return true;
		}

		private void switched_layout_handler()
		{
			switched_layout = _settings.get_boolean("switched-layout");
		}

		public void set_shader(Shader? shader)
		{
		    _editor.set_shader(shader);

		    compile();
		}

		public void compile()
		{
			_scene.shader_manager.compilation_finished.connect(() =>
			{
				compile_button_stack.visible_child_name = "compile_image";
			});

			compile_button_stack.visible_child_name = "compile_spinner";

			_scene.shader_manager.pass_compilation_terminated.connect((index, e) =>
			{
			    _editor.clear_error_messages();

				if (e != null && e is ShaderError.COMPILATION)
				{
					// append a line, so the loop below really adds all different
					// errors, very hacky
					//string errors_str = e.message;

					string[] error_lines = e.message.split("\n");

					string current_error = null;
					int last_line = -1;
					int last_row = -1;
					foreach (string error_line in error_lines)
					{
						if (":" in error_line)
						{
							string[] parsed_message = error_line.split(":", 3);
							//string error_number = parsed_message[0];
							string position = parsed_message[1];
							string error = parsed_message[2].split("error: ")[1];

							if (current_error == null)
							{
								current_error = error;
							}

							try
							{
								int prefix_length = ((string) (resources_lookup_data("/org/hasi/shady/data/shader/prefix.glsl", 0).get_data())).split("\n").length;

								string[] line_and_row = position.split("(", 2);
								int line = int.parse(line_and_row[0]) - prefix_length + 1;
								int row = int.parse(line_and_row[1][0:line_and_row[0].length]);

								if (line != last_line)
								{
									if (last_line != -1)
									{
										print(@"Line: $last_line, Row: $last_row, Error: $current_error\n");
										_editor.add_error_message("Image", last_line, @"error-$last_line-$last_row", current_error);
									}

									current_error = error;
								}
								else
								{
									current_error += "\n" + error;
								}

								last_line = line;
								last_row = row;
							}
							catch(Error e)
							{
								print("Couldn't load shader prefix\n");
							}
						}
					}

					//print(@"Line: $last_line, Row: $last_row, Error: $current_error\n");
					_editor.add_error_message("Image", last_line, @"error-$last_line-$last_row", current_error);
				}
			});

            _editor.gather_shader();
			_scene.compile(_editor.shader);
			//_scene._fullscreen_shader_manager.compile(_editor.shader);
		}

		public void reset_time()
		{
		    _scene.shader_manager.reset_time();
		}

		public void play()
		{
			_scene.shader_manager.paused = false;

			play_button_image.set_from_icon_name("media-playback-pause-symbolic", Gtk.IconSize.BUTTON);
			rubber_band_revealer.set_reveal_child(false);
		}

		public void pause()
		{
			_scene.shader_manager.paused = true;

			play_button_image.set_from_icon_name("media-playback-start-symbolic", Gtk.IconSize.BUTTON);
			rubber_band_revealer.set_reveal_child(true);
		}

		[GtkCallback]
		private void reset_button_clicked()
		{
			_scene.shader_manager.reset_time();
		}

		[GtkCallback]
		private void play_button_clicked()
		{
			if (_scene.shader_manager.paused)
			{
				play();
			}
			else
			{
				pause();
			}
		}

		[GtkCallback]
		private void rubber_band_scale_value_changed()
		{
			_scene.shader_manager.time_slider = rubber_band_scale.get_value();
		}

		[GtkCallback]
		private bool rubber_band_scale_button_released(Gdk.EventButton event)
		{
			rubber_band_scale.set_value(0);

			return false;
		}

		[GtkCallback]
		private void live_mode_button_toggled()
		{
		}

		[GtkCallback]
		private void compile_button_clicked()
		{
			compile();
		}
	}
}
