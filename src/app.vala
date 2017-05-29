namespace Shady
{
	public class App : Gtk.Application
	{
		private Gtk.CssProvider css_provider;

		private AppWindow newest_app_window;
		private AppPreferences app_preferences;

		public App()
		{
			GLib.Object(application_id: "org.hasi.shady",
			            flags: ApplicationFlags.FLAGS_NONE);

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
				// for some reason the window is display below the
				// previous one
				var new_window = new AppWindow(this, app_preferences);
				new_window.reset_time();
				new_window.play();
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
				                                            Gtk.Stock.CANCEL,
				                                            Gtk.ResponseType.CANCEL,
				                                            Gtk.Stock.OPEN,
				                                            Gtk.ResponseType.ACCEPT);

				open_dialog.local_only = false;
				open_dialog.set_modal(true);
				open_dialog.response.connect((dialog, response_id) =>
				{
					switch (response_id)
					{
						case Gtk.ResponseType.ACCEPT:
							var file = open_dialog.get_file();

							if (!newest_app_window.edited)
							{
								newest_app_window.destroy();
							}

							// for some reason the window is display below the
							// previous one
							var new_window = new AppWindow(this, app_preferences);
							new_window.set_buffer("Image", read_file_as_string(file));
							new_window.reset_time();
							new_window.compile();
							new_window.play();
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

			SimpleAction load_from_shadertoy_action = new SimpleAction("load_from_shadertoy", null);
			load_from_shadertoy_action.activate.connect(() =>
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

			this.add_action(load_from_shadertoy_action);

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

			this.add_action(quit_action);
		}

		protected override void startup()
		{
			base.startup();

			var gtk_settings = Gtk.Settings.get_default();

			// use only minimal window decorations
			gtk_settings.gtk_decoration_layout = ":close";
		}

		protected override void activate()
		{
			// don't ask
			new ShaderArea();
			new ShaderSourceView();
			new ShaderChannelTypePopover();

			app_preferences = new AppPreferences();
			newest_app_window = new AppWindow(this, app_preferences);
			newest_app_window.compile();

			load_css();

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
