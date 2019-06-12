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
			//default = false;
		}

		private bool _switched_layout = false;
		public bool switched_layout
		{
			get { return _switched_layout; }
			set
			{
				if (value != _switched_layout)
				{
					main_paned.remove(editor);
			        main_paned.remove(scene);

			        if (value)
			        {
				        main_paned.pack1(scene, true, true);
				        main_paned.pack2(editor, true, true);
			        }
			        else
			        {
				        main_paned.pack1(editor, true, true);
				        main_paned.pack2(scene, true, true);
			        }

			        compile();

			        _switched_layout = value;
				}
			}
		}

		public string shader_filename { get; set; }

		public ShaderScene scene { get; private set; }
		public ShaderEditor editor { get; private set; }

		[Signal (action=true)]
		public signal void search_toggled();

		[Signal (action=true)]
		public signal void save_as_toggled();

		[Signal (action=true)]
		public signal void escape_pressed();

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
		private Gtk.Paned main_paned;

		private Gtk.AccelGroup _accels = new Gtk.AccelGroup();
		private GLib.Settings _settings = new GLib.Settings("org.hasi.shady");

		private uint _auto_compile_handler_id;

		public AppWindow(Gtk.Application app, AppPreferences preferences)
		{
			Object(application: app);

			add_accel_group(_accels);

            scene = new ShaderScene();
			editor = new ShaderEditor();

			search_toggled.connect(() =>
			{
			    _editor.show_search();
			});

			save_as_toggled.connect(save_with_dialog);

			escape_pressed.connect(() =>
			{
			    _editor.hide_search();
			});

			key_press_event.connect((widget, event) =>
			{
			    if (event.keyval == Gdk.Key.Tab &&
			        event.state == Gdk.ModifierType.CONTROL_MASK)
			    {
			        editor.next_buffer();
			        return true;
			    }

			    if (event.keyval == Gdk.Key.ISO_Left_Tab &&
			        event.state == (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK))
			    {
			        editor.prev_buffer();
			        return true;
			    }

			    return false;
			});

			// set current switched layout state
			_switched_layout = _settings.get_boolean("switched-layout");

			if (_switched_layout)
			{
				main_paned.pack1(scene, true, true);
				main_paned.pack2(editor, true, true);
			}
			else
			{
				main_paned.pack1(editor, true, true);
				main_paned.pack2(scene, true, true);
			}

			if (!app.prefers_app_menu())
			{
				menu_button.menu_model = app.app_menu;
				menu_button.visible = true;
			}

			// react to changed editor layout
			_settings.changed["switched-layout"].connect(switched_layout_handler);

			// compile every 5 seconds, if auto compile is enabled
			_auto_compile_handler_id = Timeout.add(3000, auto_compile_handler, Priority.HIGH_IDLE);

			_shader_filename = null;
		}

		[GtkCallback]
		private void on_destroy()
		{
			// remove all handlers
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
		}

		public void compile()
		{
			editor.clear_error_messages();

			bool compilable = editor.validate_shader();
			if (compilable)
			{
			    scene.shadertoy_area.compilation_finished.connect(() =>
			    {
				    compile_button_stack.visible_child_name = "compile_image";
			    });

			    compile_button_stack.visible_child_name = "compile_spinner";

                editor.gather_shader();

                debug(@"compile: compiling shader, which is given by\n" +
                      @"$(_editor.shader)");

			    scene.compile(_editor.shader);
			    scene._fullscreen_shadertoy_area.compile(_editor.shader);
			}
		}

		public void reset_time()
		{
		    scene.shadertoy_area.reset_time();
		}

		public void play()
		{
			scene.shadertoy_area.paused = false;

			play_button_image.set_from_icon_name("media-playback-pause-symbolic", Gtk.IconSize.BUTTON);
			rubber_band_revealer.set_reveal_child(false);
		}

		public void pause()
		{
			scene.shadertoy_area.paused = true;

			play_button_image.set_from_icon_name("media-playback-start-symbolic", Gtk.IconSize.BUTTON);
			rubber_band_revealer.set_reveal_child(true);
		}

		[GtkCallback]
		private void reset_button_clicked()
		{
			scene.shadertoy_area.reset_time();
		}

		[GtkCallback]
		private void play_button_clicked()
		{
			if (scene.shadertoy_area.paused)
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
			scene.shadertoy_area.time_slider = rubber_band_scale.get_value();
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

		[GtkCallback]
		private void save_button_clicked()
		{
		    if (_shader_filename == null)
		    {
		        save_with_dialog();
			}
			else
			{
			    editor.gather_shader();

			    Core.ShyFile save_file = new Core.ShyFile.for_path(shader_filename);
		        save_file.write_shader(editor.shader);
			}
		}

		private void save_with_dialog()
		{
		    var save_dialog = new Gtk.FileChooserDialog("Choose a filename",
		                                                this as Gtk.Window,
		                                                Gtk.FileChooserAction.SAVE,
		                                                "_Cancel",
		                                                Gtk.ResponseType.CANCEL,
		                                                "_Save",
		                                                Gtk.ResponseType.ACCEPT);

		    save_dialog.local_only = false;
		    save_dialog.set_modal(true);
		    save_dialog.set_filter(Core.ShyFile.FILE_FILTER);
		    save_dialog.response.connect((dialog, response_id) =>
		    {
			    switch (response_id)
			    {
				    case Gtk.ResponseType.ACCEPT:
					    var file = save_dialog.get_file();

					    editor.gather_shader();

					    shader_filename = file.get_path();

					    if (!shader_filename.has_suffix(Core.ShyFile.FILE_EXTENSION))
					    {
					        shader_filename += Core.ShyFile.FILE_EXTENSION;
					    }

					    Core.ShyFile save_file = new Core.ShyFile.for_path(shader_filename);
	                    save_file.write_shader(editor.shader);

					    break;

				    case Gtk.ResponseType.CANCEL:
					    break;
			    }

			    save_dialog.destroy();
		    });

		    save_dialog.show();
		}
	}
}
