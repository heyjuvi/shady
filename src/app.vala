namespace Shady
{
	public class App : Gtk.Application
	{
		private Gtk.CssProvider css_provider;

		private AppWindow newest_app_window = null;
		private AppPreferences app_preferences = null;

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
				if (!newest_app_window.edited)
				{
					newest_app_window.destroy();
				}
				// for some reason the window is displayed below the
				// previous one
				var new_window = new AppWindow(this, app_preferences);
				new_window.reset_time();
				new_window.play();

				remove_window(newest_app_window);
				add_window(new_window);

				new_window.present();

				newest_app_window = new_window;
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
				open_dialog.response.connect((dialog, response_id) =>
				{
					switch (response_id)
					{
						case Gtk.ResponseType.ACCEPT:
							//var file = open_dialog.get_file();

							if (!newest_app_window.edited)
							{
								newest_app_window.destroy();
							}

							// for some reason the window is display below the
							// previous one
							var new_window = new AppWindow(this, app_preferences);

							// TODO: opening files must be solved with an appropriate file format
							//new_window.set_buffer("Image", read_file_as_string(file));
							new_window.reset_time();
							new_window.compile();
							new_window.play();

							remove_window(newest_app_window);
							add_window(new_window);

							new_window.present();

							newest_app_window = new_window;

							break;

						case Gtk.ResponseType.CANCEL:
							break;
					}

					open_dialog.destroy();
				});

				open_dialog.show();
			});

			this.add_action(open_action);

			SimpleAction search_on_shadertoy_action = new SimpleAction("search", null);
			search_on_shadertoy_action.activate.connect(() =>
			{
				var shadertoy_search_dialog = new Shady.ShadertoySearchDialog(newest_app_window);

				shadertoy_search_dialog.response.connect((dialog, response_id) =>
				{
					switch (response_id)
					{
						case Gtk.ResponseType.ACCEPT:
							if (!newest_app_window.edited)
							{
								newest_app_window.destroy();
							}

							// for some reason the window is display below the
							// previous one
							var new_window = new AppWindow(this, app_preferences);
							new_window.set_shader(shadertoy_search_dialog.selected_shader);
							new_window.reset_time();
							new_window.compile();
							new_window.play();

							remove_window(newest_app_window);
							add_window(new_window);

							new_window.present();

							newest_app_window = new_window;

							break;

						case Gtk.ResponseType.CANCEL:
							break;
					}

					shadertoy_search_dialog.destroy();
				});

				shadertoy_search_dialog.show();
			});

			this.add_action(search_on_shadertoy_action);

			SimpleAction preferences_action = new SimpleAction("preferences", null);
			preferences_action.activate.connect(() =>
			{
				app_preferences.present();
			});

			this.add_action(preferences_action);

			SimpleAction quit_action = new SimpleAction("quit", null);
			quit_action.activate.connect(() =>
			{
				this.quit();
			});

			add_action(quit_action);
		}

		protected override void startup()
		{
			base.startup();

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
			new NotebookActionWidget();
			//new ShaderEditor();
			//new ShaderChannel();

			ShaderSourceBuffer.initialize_resources();

			app_preferences = new AppPreferences();
			newest_app_window = new AppWindow(this, app_preferences);

			load_css();

			add_window(newest_app_window);

			newest_app_window.present();
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
