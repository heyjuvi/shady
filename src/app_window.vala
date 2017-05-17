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

		private ShaderArea shader_area;

		private ScrolledWindow scrolled_source;
		private SourceView source_view;
		public SourceBuffer source_buffer;
		private SourceLanguage source_language;
		private SourceLanguageManager source_language_manager;

		private bool _is_fullscreen = false;

		public AppWindow(Gtk.Application app)
		{
			Object(application: app);

			string defaultShader = read_file_as_string(File.new_for_uri("resource:///org/hasi/shady/data/shader/default.glsl"));

			shader_area = new ShaderArea(defaultShader);
			shader_area.set_size_request(560, 640);

			main_paned.pack2(shader_area, true, true);

			source_language_manager = SourceLanguageManager.get_default();;
			source_language = source_language_manager.get_language("glsl");

			source_buffer = new source_buffer.with_language(source_language);
			source_buffer.text = defaultShader;

			source_buffer.changed.connect(() =>
			{
				_edited = true;
			});

			source_view = new SourceView.with_buffer(source_buffer);

			source_view.show_line_numbers = true;
			source_view.show_line_marks = true;
			source_view.tab_width = 2;
			source_view.indent_on_tab = true;
			source_view.auto_indent = true;
			source_view.highlight_current_line = true;

			source_view.override_font(FontDescription.from_string("Monospace"));

			scrolled_source = new ScrolledWindow(null, null);
			scrolled_source.set_size_request(720, 640);

			scrolled_source.add(source_view);

			main_paned.pack1(scrolled_source, true, true);

			menu_button.menu_model = app.app_menu;

			button_press_event.connect((widget, event) =>
			{
				if (event.button == Gdk.BUTTON_PRIMARY)
				{
					shader_area.button_press(event.x, event.y);
				}

				return false;
			});

			button_release_event.connect((widget, event) =>
			{
				if(event.button == Gdk.BUTTON_PRIMARY)
				{
					shader_area.button_release(event.x, event.y);
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
					scrolled_source.hide();
				}
				else
				{
					scrolled_source.show();
				}

				return false;
			});

			show_all();

			fps_label.draw.connect(update_fps);
			time_label.draw.connect(update_time);

		}

		public void compile() throws ShaderError
		{
			shader_area.compile(source_buffer.text);
		}

		public void reset_time()
		{
			shader_area.reset_time();
		}

		public void play()
		{
			shader_area.pause(false);

			play_button_image.set_from_icon_name("media-playback-pause-symbolic", Gtk.IconSize.BUTTON);
			rubber_band_revealer.set_reveal_child(false);
		}

		public void pause()
		{
			shader_area.pause(true);

			play_button_image.set_from_icon_name("media-playback-start-symbolic", Gtk.IconSize.BUTTON);
			rubber_band_revealer.set_reveal_child(true);
		}

		public bool update_fps()
		{
			StringBuilder fps = new StringBuilder();
			fps.printf("%07.2f", shader_area.fps);
			fps_label.set_label(fps.str);

			return false;
		}

		public bool update_time()
		{
			StringBuilder time = new StringBuilder();
			time.printf("%05.2f", shader_area.time);
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
			if (shader_area.paused)
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
			scrolled_source.hide();
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
