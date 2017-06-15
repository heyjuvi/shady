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
					if (live_mode)
					{
						main_paned.remove(_shader_overlay);

						if (value)
						{
							main_paned.pack1(_shader_overlay, true, true);
						}
						else
						{
							main_paned.pack2(_shader_overlay, true, true);
						}
					}
					else
					{
						main_paned.remove(_editor_box);
						main_paned.remove(_shader_overlay);

						if (value)
						{
							main_paned.pack1(_shader_overlay, true, true);
							main_paned.pack2(_editor_box, true, true);
						}
						else
						{
							main_paned.pack1(_editor_box, true, true);
							main_paned.pack2(_shader_overlay, true, true);
						}

						compile();
					}
				}

				_switched_layout = value;
			}
		}

		private bool _live_mode = false;
		public bool live_mode
		{
			get { return _live_mode; }
			set
			{
				if (value != _live_mode)
				{
					foreach (string key in _shader_buffers.get_keys())
					{
						_shader_buffers[key].live_mode = value;
					}

					if (value)
					{
						main_paned.remove(_editor_box);
						_foreground_box.pack_start(_editor_box, true, true);

						_editor_notebook.get_style_context().add_class("live_mode");
					}
					else
					{
						_foreground_box.remove(_editor_box);

						if (switched_layout)
						{
							main_paned.pack2(_editor_box, true, true);
						}
						else
						{
							main_paned.pack1(_editor_box, true, true);
						}

						_editor_notebook.get_style_context().remove_class("live_mode");
					}
				}

				_editor_notebook.show_tabs = !value;

				_live_mode = value;
			}
		}

		[GtkChild]
		private HeaderBar header_bar;

		[GtkChild]
		private Gtk.MenuButton menu_button;

		[GtkChild]
		private Gtk.ToggleButton live_mode_button;

		[GtkChild]
		private Gtk.Image play_button_image;

		[GtkChild]
		private Gtk.Revealer rubber_band_revealer;

		[GtkChild]
		private Gtk.Scale rubber_band_scale;

		[GtkChild]
		private Gtk.Label fps_label;

		[GtkChild]
		private Gtk.Label time_label;

		[GtkChild]
		private Gtk.Paned main_paned;

		private Overlay _shader_overlay;
		private ShaderArea _shader_area;
		private Box _foreground_box;

		private Gtk.Box _editor_box;

		private Notebook _editor_notebook;
		private NotebookActionWidget _notebook_action_widget;
		private HashTable<string, ShaderSourceBuffer> _shader_buffers = new HashTable<string, ShaderSourceBuffer>(str_hash, str_equal);

		private Gtk.Revealer _channels_revealer;
		private Gtk.Box _channels_box;

		private GLib.Settings _settings = new GLib.Settings("org.hasi.shady");

		private string _default_code;
		private Shader _curr_shader;

		private uint _auto_compile_handler_id;
		private bool _is_fullscreen = false;

		public AppWindow(Gtk.Application app, AppPreferences preferences)
		{
			Object(application: app);

			_default_code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/default.glsl", 0).get_data());

			_curr_shader = new Shader();

			Shader.Renderpass renderpass = new Shader.Renderpass();

			renderpass.code = _default_code;
			renderpass.type = Shader.RenderpassType.IMAGE;

			_curr_shader.renderpasses.append_val(renderpass);

			_shader_area = new ShaderArea(_curr_shader);
			_shader_area.set_size_request(500, 600);

			_foreground_box = new Box(Orientation.VERTICAL, 0);

			Box dummy = new Box(Orientation.HORIZONTAL, 0);

			dummy.pack_start(new Box(Orientation.VERTICAL, 0), true, true);
			dummy.pack_start(_foreground_box, true, false);
			dummy.pack_end(new Box(Orientation.VERTICAL, 0), true, true);

			_shader_overlay = new Overlay();
			_shader_overlay.add(_shader_area);
			_shader_overlay.add_overlay(dummy);

			_shader_overlay.set_overlay_pass_through(dummy,true);

			_editor_box = new Gtk.Box(Orientation.VERTICAL, 0);

			_editor_notebook = new Notebook();
			_editor_notebook.tab_pos = PositionType.BOTTOM;
			_editor_notebook.show_border = false;

			_notebook_action_widget = new NotebookActionWidget();
			_editor_notebook.set_action_widget(_notebook_action_widget, PackType.END);

			_editor_box.pack_start(_editor_notebook, true, true);

			_channels_revealer = new Gtk.Revealer();

			_channels_box = new Gtk.Box(Orientation.HORIZONTAL, 12);
			_channels_box.get_style_context().add_class("channels_box_margin");
			//_channels_flow_box.set_size_request(0, 140);
			//_channels_box.selection_mode = Gtk.SelectionMode.NONE;
			//_channels_box.min_children_per_line = 6;

			_channels_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
			_channels_revealer.add(_channels_box);

			_editor_box.pack_end(_channels_revealer, false, true);

			// set current switched layout state
			_switched_layout = _settings.get_boolean("switched-layout");

			if (_switched_layout)
			{
				main_paned.pack1(_shader_overlay, true, true);
				main_paned.pack2(_editor_box, true, true);
			}
			else
			{
				main_paned.pack1(_editor_box, true, true);
				main_paned.pack2(_shader_overlay, true, true);
			}

			menu_button.menu_model = app.app_menu;

			_notebook_action_widget.new_buffer_button.clicked.connect(add_buffer_alphabetically);

			_notebook_action_widget.show_channels_button.clicked.connect(() =>
			{
				_channels_revealer.reveal_child = !_channels_revealer.reveal_child;
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

				if (is_fullscreen && live_mode && event.keyval == Gdk.Key.Control_R)
				{
					_editor_box.set_visible(!_editor_box.get_visible());
				}

				return false;
			});

			window_state_event.connect((event) =>
			{
				bool is_fullscreen = (get_window().get_state() & Gdk.WindowState.FULLSCREEN) == Gdk.WindowState.FULLSCREEN;

				_editor_box.visible = !is_fullscreen || live_mode;
				_editor_notebook.show_tabs = !live_mode;

				return false;
			});

			// react to changed editor layout
			_settings.changed["switched-layout"].connect(switched_layout_handler);

			// compile every 5 seconds, if auto compile is enabled
			_auto_compile_handler_id = Timeout.add(3000, auto_compile_handler, Priority.HIGH_IDLE);

			fps_label.draw.connect(update_fps);
			time_label.draw.connect(update_time);

			add_buffer("Image", false);
			set_buffer("Image", _default_code);

			_edited = false;

			show_all();

			// test
			ShaderChannel channel0 = new ShaderChannel();
			channel0.channel_name = "iChannel0";
			ShaderChannel channel1 = new ShaderChannel();
			channel1.channel_name = "iChannel1";
			ShaderChannel channel2 = new ShaderChannel();
			channel2.channel_name = "iChannel2";
			ShaderChannel channel3 = new ShaderChannel();
			channel3.channel_name = "iChannel3";

			_channels_box.pack_start(channel0, false, true);
			_channels_box.pack_start(channel1, false, true);
			_channels_box.pack_start(channel2, false, true);
			_channels_box.pack_start(channel3, false, true);
			// end test
		}

		public void set_shader(Shader? shader)
		{
			_shader_buffers.remove_all();

			for (int i = 0; i < _editor_notebook.get_n_pages(); i++)
			{
				_editor_notebook.remove_page(i);
			}

			if (shader != null)
			{
				List<string> sorted_keys = new List<string>();

				Shader.Renderpass audio_renderpass = null;
				Shader.Renderpass image_renderpass = null;

				for (int i = 0; i < shader.renderpasses.length; i++)
				{
					if (shader.renderpasses.index(i) is Shader.Renderpass)
					{
						Shader.Renderpass renderpass = shader.renderpasses.index(i) as Shader.Renderpass;

						if (renderpass.type != Shader.RenderpassType.AUDIO)
						{
							audio_renderpass = renderpass;
						}
						else if (renderpass.type != Shader.RenderpassType.IMAGE)
						{
							image_renderpass = renderpass;
						}
						else
						{
							sorted_keys.insert_sorted(renderpass.name, strcmp);
						}
					}
				}

				if (audio_renderpass != null)
				{
				}

				if (image_renderpass != null)
				{
					add_buffer("Image", false);
					set_buffer("Image", image_renderpass.code);
				}

				foreach (string renderpass_name in sorted_keys)
				{
					for (int i = 0; i < shader.renderpasses.length; i++)
					{
						if (shader.renderpasses.index(i) is Shader.Renderpass)
						{
							Shader.Renderpass renderpass = shader.renderpasses.index(i) as Shader.Renderpass;

							if (renderpass.name == renderpass_name)
							{
								add_buffer(renderpass_name);
								set_buffer(renderpass_name, renderpass.code);
							}
						}
					}
				}
			}
		}

		public void set_buffer(string buffer_name, string content)
		{
			_shader_buffers[buffer_name].buffer.text = content;
		}

		public string get_buffer(string buffer_name)
		{
			return _shader_buffers[buffer_name].buffer.text;
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

		private void add_buffer_alphabetically()
		{
			int i = 0;

			string buffer_name = @"Buf $((char) (0x41 + i))";
			while (buffer_name in _shader_buffers)
			{
				i++;
				buffer_name = @"Buf $((char) (0x41 + i))";
			}

			add_buffer(buffer_name);
		}

		private void add_buffer(string buffer_name, bool show_close_button=true)
		{
			ShaderSourceBuffer shader_buffer = new ShaderSourceBuffer(buffer_name);
			shader_buffer.buffer.changed.connect(() =>
			{
				_edited = true;
			});

			shader_buffer.button_press_event.connect((widget, event) =>
			{
				_channels_revealer.reveal_child = false;

				return false;
			});

			NotebookTabLabel shader_buffer_label = new NotebookTabLabel.with_title(buffer_name);
			shader_buffer_label.show_close_button = show_close_button;
			shader_buffer_label.close_clicked.connect(() =>
			{
				remove_buffer(buffer_name);
			});

			_shader_buffers.insert(buffer_name, shader_buffer);
			_editor_notebook.append_page(shader_buffer, shader_buffer_label);
		}

		private void remove_buffer(string buffer_name)
		{
			_editor_notebook.remove_page(_editor_notebook.page_num(_shader_buffers[buffer_name]));
			_shader_buffers.remove(buffer_name);
		}

		public void compile() throws ShaderError
		{
			for(int i=0; i<_curr_shader.renderpasses.length;i++)
			{
				if(_curr_shader.renderpasses.index(i).type == Shader.RenderpassType.IMAGE)
				{
					_curr_shader.renderpasses.index(i).code = get_buffer("Image");
				}
			}

			_shader_area.compile(_curr_shader);
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
			_shader_area.time_slider=rubber_band_scale.get_value();
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
			if (!live_mode)
			{
				_editor_box.hide();
			}

			fullscreen();
		}

		[GtkCallback]
		private void live_mode_button_toggled()
		{
			live_mode = live_mode_button.get_active();
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
