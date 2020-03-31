namespace Shady
{
	public class App : Gtk.Application
	{
		private Gtk.CssProvider css_provider;

		private AppWindow newest_app_window = null;
		public static AppPreferences app_preferences{ get; private set; default = null; }

		public App()
		{
			GLib.Object(application_id: "org.hasi.shady",
			            flags: ApplicationFlags.HANDLES_OPEN);

			add_actions();
		}

		private void add_actions()
		{
			SimpleAction new_action = new SimpleAction("new", null);
			new_action.activate.connect(() =>
			{
				if (!newest_app_window.editor.edited)
				{
					newest_app_window.destroy();
				}

				// for some reason the window is displayed below the
				// previous one
				var new_window = new AppWindow(this, app_preferences);

				add_window(new_window);

				newest_app_window = new_window;

				new_window.present();

				new_window.reset_time();
				new_window.play();
			});

			this.add_action(new_action);

			SimpleAction open_action = new SimpleAction("open", null);
			open_action.activate.connect(() =>
			{
				var open_dialog = new Gtk.FileChooserDialog("Pick a file",
				                                            newest_app_window as Gtk.Window,
				                                            Gtk.FileChooserAction.OPEN,
				                                            "_Cancel",
				                                            Gtk.ResponseType.CANCEL,
				                                            "_Open",
				                                            Gtk.ResponseType.ACCEPT);

				open_dialog.local_only = false;
				open_dialog.set_modal(true);
				open_dialog.set_filter(Core.ShyFile.FILE_FILTER);
				open_dialog.response.connect((dialog, response_id) =>
				{
					switch (response_id)
					{
						case Gtk.ResponseType.ACCEPT:
							var file = open_dialog.get_file();

							Core.ShyFile open_file = new Core.ShyFile.for_file(file);
							Shader? new_shader = open_file.read_shader();

                            if (new_shader != null)
                            {
							    if (!newest_app_window.editor.edited)
							    {
								    newest_app_window.destroy();
							    }

							    // for some reason the window is displayed below the
							    // previous one
							    var new_window = new AppWindow(this, app_preferences, ShaderArea.get_loading_shader());

							    add_window(new_window);

							    newest_app_window = new_window;

							    new_window.present();

							    new_window.shader_filename = file.get_path();
                                new_window.set_shader(new_shader);

                                new_window.compile();
							    new_window.reset_time();
							    new_window.play();
							}

							break;

						case Gtk.ResponseType.CANCEL:
							break;
					}

					open_dialog.destroy();
				});

				open_dialog.show();
			});

			this.add_action(open_action);

			SimpleAction preferences_action = new SimpleAction("preferences", null);
			preferences_action.activate.connect(() =>
			{
			    app_preferences.set_transient_for(newest_app_window);
				app_preferences.present();
			});

			this.add_action(preferences_action);

			SimpleAction quit_action = new SimpleAction("quit", null);
			quit_action.activate.connect(() =>
			{
				this.quit();
			});

			this.add_action(quit_action);
		}

		protected override void startup()
		{
			base.startup();

            var builder = new Gtk.Builder.from_resource ("/org/hasi/shady/gtk/menus.ui");
            var app_menu = builder.get_object("app-menu") as GLib.MenuModel;
			set_app_menu(app_menu);

			var gtk_settings = Gtk.Settings.get_default();

			// use only minimal window decorations
			gtk_settings.gtk_decoration_layout = ":close";
			gtk_settings.gtk_application_prefer_dark_theme = true;
		}

		protected override void activate()
		{
			// don't ask
			//new ShaderArea();
			new ShaderSourceView();
			new ShaderChannelTypePopover();
			new ShadertoyResourceManager();
			new ShaderSourceBufferAddPopover();
			new NotebookActionWidget();
			new Shader();
			//new ShaderEditor();
			//new ShaderChannel();

			ShaderSourceBuffer.initialize_resources();

			app_preferences = new AppPreferences();
			newest_app_window = new AppWindow(this, app_preferences);

			load_css();

			add_window(newest_app_window);

			newest_app_window.present();

			newest_app_window.reset_time();
			newest_app_window.play();
		}

		private void load_css()
		{
			css_provider = new Gtk.CssProvider();
			css_provider.load_from_resource("/org/hasi/shady/data/css/shady.css");

			var screen = newest_app_window.get_screen();
			Gtk.StyleContext.add_provider_for_screen(screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		}
	}
}
