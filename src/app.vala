namespace Shady
{
	public class App : Gtk.Application
	{
		private Gtk.CssProvider css_provider;

		private AppWindow window;

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
				if (!window.edited)
				{
					window.destroy();
				}

				// for some reason the window is display below the
				// previous one
				var new_window = new AppWindow(this);
				new_window.reset_time();
				new_window.play();
				new_window.present();

				window = new_window;
			});

			this.add_action(new_action);

			SimpleAction open_action = new SimpleAction("open", null);
			open_action.activate.connect(() =>
			{
				var open_dialog = new Gtk.FileChooserDialog("Pick a file",
				                                            window as Gtk.Window,
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

							if (!window.edited)
							{
								window.destroy();
							}

							// for some reason the window is display below the
							// previous one
							var new_window = new AppWindow(this);
							new_window.source_buffer.text = read_file_as_string(file);
							new_window.reset_time();
							new_window.compile();
							new_window.play();
							new_window.present();

							window = new_window;

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
				var shadertoy_search_dialog = new Shady.ShadertoySearchDialog(window);

				shadertoy_search_dialog.response.connect((dialog, response_id) =>
				{
					switch (response_id)
					{
						case Gtk.ResponseType.ACCEPT:
							if (!window.edited)
							{
								window.destroy();
							}

							// for some reason the window is display below the
							// previous one
							var new_window = new AppWindow(this);
							new_window.source_buffer.text = shadertoy_search_dialog.selected_shader;
							new_window.reset_time();
							new_window.compile();
							new_window.play();
							new_window.present();

							window = new_window;
							break;

						case Gtk.ResponseType.CANCEL:
							break;
					}

					shadertoy_search_dialog.destroy();
				});

				shadertoy_search_dialog.show();
			});

			this.add_action(load_from_shadertoy_action);

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

			window = new Shady.AppWindow(this);

			load_css();

			window.show();
		}

		private void load_css()
		{
			css_provider = new Gtk.CssProvider();
			css_provider.load_from_resource("/org/hasi/shady/data/css/shady.css");

			var screen = this.window.get_screen();
			Gtk.StyleContext.add_provider_for_screen(screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		}
	}
}
