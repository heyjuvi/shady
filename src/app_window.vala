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
		private Button reset_button;

		[GtkChild]
		private Button play_button;

		[GtkChild]
		private Image play_button_image;

		[GtkChild]
		private Button compile_button;

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

			string defaultShader = "void mainImage( out vec4 fragColor, in vec2 fragCoord )\n{\n\tvec2 uv = fragCoord.xy / iResolution.xy;\n\tfragColor = vec4(uv,0.5+0.5*sin(iGlobalTime),1.0);\n}";

			shader_area = new ShaderArea(defaultShader);
			shader_area.set_size_request(400, 520);

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
			scrolled_source.set_size_request(600, 520);

			scrolled_source.add(source_view);

			main_paned.pack1(scrolled_source, true, true);

			menu_button.menu_model = app.app_menu;

			key_press_event.connect((widget, event) =>
			{
				bool is_fullscreen = (get_window().get_state() & Gdk.WindowState.FULLSCREEN) == Gdk.WindowState.FULLSCREEN;

				if (event.keyval == Gdk.Key.F11)
				{
					if (is_fullscreen)
					{
						unfullscreen();
						scrolled_source.show();
					}
					else
					{
						scrolled_source.hide();
						fullscreen();
					}
				}

				if (is_fullscreen && event.keyval == Gdk.Key.Escape)
				{
					unfullscreen();
					scrolled_source.show();
				}

				return false;
			});

			show_all();
		}

		public void reset_time()
		{
			shader_area.reset_time();
		}

		public void play()
		{
			shader_area.compile(source_buffer.text);
			shader_area.pause(false);
			shader_area.queue_draw();

			play_button_image.set_from_icon_name("media-playback-pause", Gtk.IconSize.BUTTON);
		}

		public void pause()
		{
			shader_area.pause(true);

			play_button_image.set_from_icon_name("media-playback-start", Gtk.IconSize.BUTTON);
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
		private void fullscreen_button_clicked()
		{
			scrolled_source.hide();
			fullscreen();
		}

		[GtkCallback]
		private void compile_button_clicked()
		{
			shader_area.compile(source_buffer.text);

			shader_area.queue_draw();
		}
	}
}
