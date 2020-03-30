using GL;
using Gtk;
using Pango;

namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/app-window.ui")]
	public class AppWindow : Gtk.ApplicationWindow
	{
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
		private Gtk.Stack header_stack;

		[GtkChild]
		private Gtk.Stack content_stack;

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

		[GtkChild]
		private Gtk.SearchEntry shadertoy_search_entry;

		[GtkChild]
		private Gtk.Button load_shader_button;

		[GtkChild]
		private Gtk.Stack search_content_stack;

		[GtkChild]
		private Gtk.Label loading_label;

		[GtkChild]
		private Gtk.FlowBox shader_box;

		private Gtk.AccelGroup _accels = new Gtk.AccelGroup();
		private GLib.Settings _settings = new GLib.Settings("org.hasi.shady");

		private uint _auto_compile_handler_id;

		private int _last_index = 0;
		private string _current_search_child = "search_results";

		private Shader?[] _found_shaders = null;
		private Shader _selected_search_shader = null;

		public AppWindow(Gtk.Application app, AppPreferences preferences, Shader? shader=null)
		{
			Object(application: app);

			add_accel_group(_accels);

            if (shader == null)
            {
                scene = new ShaderScene();
            }
            else
            {
                scene = new ShaderScene(shader);
            }

			editor = new ShaderEditor();

			search_toggled.connect(() =>
			{
			    _editor.show_search();
			});

			save_as_toggled.connect(save_with_dialog);

			escape_pressed.connect(() =>
			{
			    if (content_stack.visible_child_name == "content")
			    {
			        _editor.hide_search();
			    }
			    else if (content_stack.visible_child_name == "search_content")
			    {
			        cancel_search_button_clicked();
			    }
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

			scene.shadertoy_area.compilation_finished.connect(() =>
		    {
			    compile_button_stack.visible_child_name = "compile_image";
		    });

			_shader_filename = null;

            // this is necessary, since the show-menubar value inside the ui file is not
            // respected, if the GtkStack is the root of the titlebar instead of GtkHeaderBar,
            // is this a bug?
			set_show_menubar(false);
		}

		[GtkCallback]
		private void on_destroy()
		{
			// remove all handlers
			_settings.changed["switched-layout"].disconnect(switched_layout_handler);
			Source.remove(_auto_compile_handler_id);

			editor.prepare_destruction();
		}

        /*
         * Editor part
         */
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
			    compile_button_stack.visible_child_name = "compile_spinner";

                editor.gather_shader();

                debug(@"compile: compiling shader, which is given by\n" +
                      @"$(_editor.shader)");

			    scene.compile(_editor.shader);
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
		private void search_button_clicked()
		{
		    scene.shadertoy_area.paused = true;

		    header_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT);
		    header_stack.set_visible_child_name("search_header_bar");
		    content_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT);
		    content_stack.set_visible_child_name("search_content");

		    shadertoy_search_entry.grab_focus();
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

		/*
         * Shadertoy search part
         */
        [GtkCallback]
		private bool search_key_entry_pressed(Gdk.EventKey event_key)
		{
			if (event_key.keyval == Gdk.Key.Return)
			{
				if (shadertoy_search_entry.text != "")
				{
					search(shadertoy_search_entry.text);
				}
			}

			return false;
		}

		[GtkCallback]
		private void selected_children_changed()
		{
			if (shader_box.get_selected_children().length() == 1)
			{
				ShadertoyShaderItem selected_shadertoy_item = shader_box.get_selected_children().nth_data(0) as ShadertoyShaderItem;
				_selected_search_shader = new Shader();
				_selected_search_shader.assign(selected_shadertoy_item.shader);

				load_shader_button.sensitive = true;
			}
		}

		private void show_n_more_shaders(int n)
		{
		    if (n == 0)
		    {
		        return;
		    }

		    if (_found_shaders != null && _last_index < _found_shaders.length)
			{
			    int loc_index = _last_index;
				_last_index++;

				if (_found_shaders[loc_index] != null)
				{
					ShadertoyShaderItem element = new ShadertoyShaderItem();
					shader_box.add(element);

					debug(@"show_n_more_shaders: adding shader $(_found_shaders[loc_index].shader_name) with index $(loc_index)");

			        element.sh_it_name = _found_shaders[loc_index].shader_name;
			        element.author = _found_shaders[loc_index].author;
			        element.likes = (int) _found_shaders[loc_index].likes;
			        element.views = (int) _found_shaders[loc_index].views;
			        element.shader = _found_shaders[loc_index];

			        element._shadertoy_area.initialized.connect(() =>
			        {
			            show_n_more_shaders(n - 1);
			        });

			        try
			        {
			            debug(@@"show_n_more_shaders: Compiling $(element.sh_it_name)");
				        element.compile();
			        }
			        catch (ShaderError e)
			        {
				        warning(@"show_n_more_shaders: compilation error: $(e.message)");
			        }
				}
			}
		}

		[GtkCallback]
		private void visible_child_changed()
		{
			if (search_content_stack.visible_child_name == "search_results" &&
			    search_content_stack.visible_child_name != _current_search_child)
			{
				_last_index = 0;

				show_n_more_shaders(16);

				/*for (int i = 0; i < 4; i++)
				{
					show_n_more_shaders(4);

					Gtk.Allocation allocation;
					shader_box.get_allocated_size(out allocation, null);

					if (allocation.y > 20)
					{
						break;
					}
				}*/

				/*Gtk.Allocation allocation;
				shader_box.get_allocation(out allocation);
				while (allocation.y < 100 && _last_index < _found_shaders.length);
				{
					show_n_more_shaders(4);

					Thread.usleep(500000);

					shader_box.get_allocation(out allocation);
				}*/
			}

			// for some reason the corresponding signal is emitted twice, so
			// we have to remember the state
			_current_search_child = search_content_stack.visible_child_name;
		}

		[GtkCallback]
		private void edge_reached(Gtk.PositionType position_type)
		{
			if (position_type == Gtk.PositionType.BOTTOM)
			{
				if (_last_index < _found_shaders.length)
				{
					show_n_more_shaders(4);
				}
			}
		}

		[GtkCallback]
		private void cancel_search_button_clicked()
		{
		    header_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_RIGHT);
		    header_stack.set_visible_child_name("header_bar");
		    content_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_RIGHT);
		    content_stack.set_visible_child_name("content");

		    scene.shadertoy_area.paused = false;
		}

		[GtkCallback]
		private void load_shader_button_clicked()
		{
		    header_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_RIGHT);
		    header_stack.set_visible_child_name("header_bar");
		    content_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_RIGHT);
		    content_stack.set_visible_child_name("content");

		    scene.shadertoy_area.paused = false;

            set_shader(_selected_search_shader);
		    compile();
		}

		public void search(string search_string)
		{
			shader_box.forall((widget) =>
			{
				shader_box.remove(widget);
			});

			loading_label.set_text("Loading shaders...");
			search_content_stack.visible_child_name = "spinner";
			shadertoy_search_entry.sensitive = false;

			ShadertoySearch shadertoy_search = new ShadertoySearch();

			shadertoy_search.download_proceeded.connect((count, num_shaders) =>
			{
			    loading_label.set_text(@"Loaded $count/$num_shaders shaders...");
			});

			shadertoy_search.search.begin(search_string, (object, resource) =>
			{
			    _found_shaders = shadertoy_search.search.end(resource);

			    search_content_stack.visible_child_name = "search_results";
                shadertoy_search_entry.sensitive = true;
			});
		}
	}
}
