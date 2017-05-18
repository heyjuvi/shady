using GL;
using Gtk;
using Pango;

namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/app-window.ui")]
	public class AppWindow : ApplicationWindow
	{
		private bool _edited;
		public bool edited
		{
			get { return _edited; }
			default = false;
		}

		public string shader
		{
			owned get { return _source_buffer.text; }
			set { _source_buffer.text = value; }
		}


		private bool _switched_layout = false;
		public bool switched_layout
		{
			get { return _switched_layout; }
			set
			{
				if (value != _switched_layout)
				{
					main_paned.remove(_scrolled_source);
					main_paned.remove(_shader_area);

					if (value)
					{
						main_paned.pack1(_shader_area, true, true);
						main_paned.pack2(_scrolled_source, true, true);
					}
					else
					{
						main_paned.pack1(_scrolled_source, true, true);
						main_paned.pack2(_shader_area, true, true);
					}

					compile();
				}

				_switched_layout = value;
			}
		}

		[GtkChild]
		private HeaderBar header_bar;

		[GtkChild]
		private Gtk.MenuButton menu_button;

		[GtkChild]
		private Image play_button_image;

		[GtkChild]
		private Gtk.Revealer rubber_band_revealer;

		[GtkChild]
		private Gtk.Scale rubber_band_scale;

		[GtkChild]
		private Label fps_label;

		[GtkChild]
		private Label time_label;

		[GtkChild]
		private Paned main_paned;

		private ShaderArea _shader_area;

		private ScrolledWindow _scrolled_source;
		private SourceView _source_view;
		private SourceBuffer _source_buffer;
		private SourceLanguage _source_language;
		private SourceLanguageManager _source_language_manager;

		private GLib.Settings _settings;

		private uint _auto_compile_handler_id;
		private bool _is_fullscreen = false;

		public AppWindow(Gtk.Application app, AppPreferences preferences)
		{
			Object(application: app);

			_settings = new GLib.Settings("org.hasi.shady");

			string default_shader = read_file_as_string(File.new_for_uri("resource:///org/hasi/shady/data/shader/default.glsl"));

			_shader_area = new ShaderArea(default_shader);
			_shader_area.set_size_request(500, 600);

			_source_language_manager = SourceLanguageManager.get_default();;
			_source_language = _source_language_manager.get_language("glsl");

			_source_buffer = new SourceBuffer.with_language(_source_language);
			_source_buffer.text = default_shader;

			_source_buffer.changed.connect(() =>
			{
				_edited = true;
			});

			_source_view = new SourceView.with_buffer(_source_buffer);

			_source_view.show_line_numbers = true;
			_source_view.show_line_marks = true;
			_source_view.tab_width = 2;
			_source_view.indent_on_tab = true;
			_source_view.auto_indent = true;
			_source_view.highlight_current_line = true;

			_source_view.override_font(FontDescription.from_string("Monospace"));

			_scrolled_source = new ScrolledWindow(null, null);
			_scrolled_source.set_size_request(680, 600);

			_scrolled_source.add(_source_view);

			// set current switched layout state
			bool inital_switched_layout = _settings.get_boolean("switched-layout");

			if (inital_switched_layout)
			{
				main_paned.pack1(_shader_area, true, true);
				main_paned.pack2(_scrolled_source, true, true);
			}
			else
			{
				main_paned.pack1(_scrolled_source, true, true);
				main_paned.pack2(_shader_area, true, true);
			}

			menu_button.menu_model = app.app_menu;

			button_press_event.connect((widget, event) =>
			{
				if (event.button == Gdk.BUTTON_PRIMARY)
				{
					_shader_area.button_press(event.x, event.y);
				}

				return false;
			});

			button_release_event.connect((widget, event) =>
			{
				if (event.button == Gdk.BUTTON_PRIMARY)
				{
					_shader_area.button_release(event.x, event.y);
				}

				return false;
			});

			key_press_event.connect((widget, event) =>
			{
				bool is_fullscreen = (get_window().get_state() & Gdk.WindowState.FULLSCREEN) == Gdk.WindowState.FULLSCREEN;

				if (event.keyval == Gdk.Key.F11)
				{
					if (is_fullscreen)
					{
						unfullscreen();
					}
					else
					{
						fullscreen();
					}
				}

				if (is_fullscreen && event.keyval == Gdk.Key.Escape)
				{
					unfullscreen();
				}

				return false;
			});

			window_state_event.connect((event) =>
			{
				bool is_fullscreen = (get_window().get_state() & Gdk.WindowState.FULLSCREEN) == Gdk.WindowState.FULLSCREEN;

				if (is_fullscreen)
				{
					_scrolled_source.hide();
				}
				else
				{
					_scrolled_source.show();
				}

				return false;
			});

			// react to changed editor layout
			_settings.changed["switched-layout"].connect(switched_layout_handler);

			// compile every 5 seconds, if auto compile is enabled
			_auto_compile_handler_id = Timeout.add(5000, auto_compile_handler, Priority.DEFAULT_IDLE);

			fps_label.draw.connect(update_fps);
			time_label.draw.connect(update_time);

			show_all();
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

		public void compile() throws ShaderError
		{
			_shader_area.compile(shader);
		}

		public void reset_time()
		{
			_shader_area.reset_time();
		}

		public void play()
		{
			_shader_area.pause(false);

			play_button_image.set_from_icon_name("media-playback-pause-symbolic", Gtk.IconSize.BUTTON);
			rubber_band_revealer.set_reveal_child(false);
		}

		public void pause()
		{
			_shader_area.pause(true);

			play_button_image.set_from_icon_name("media-playback-start-symbolic", Gtk.IconSize.BUTTON);
			rubber_band_revealer.set_reveal_child(true);
		}

		public bool update_fps()
		{
			StringBuilder fps = new StringBuilder();

			fps.printf("%5.2ffps", _shader_area.fps);
			fps_label.set_label(fps.str);

			return false;
		}

		public bool update_time()
		{
			StringBuilder time = new StringBuilder();

			time.printf("%3.2fs", _shader_area.time);
			time_label.set_label(time.str);

			return false;
		}

		[GtkCallback]
		private void reset_button_clicked()
		{
			reset_time();
		}

		[GtkCallback]
		private void play_button_clicked()
		{
			if (_shader_area.paused)
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
			print(@"$(rubber_band_scale.get_value())\n");
		}

		[GtkCallback]
		private bool rubber_band_scale_button_released(Gdk.EventButton event)
		{
			rubber_band_scale.set_value(0);

			return false;
		}

		[GtkCallback]
		private void fullscreen_button_clicked()
		{
			_scrolled_source.hide();
			fullscreen();
		}

		[GtkCallback]
		private void compile_button_clicked()
		{
			try
			{
				compile();
			}
			catch (ShaderError e)
			{
				print(@"Compilation error: $(e.message)");
			}
		}
	}
}
