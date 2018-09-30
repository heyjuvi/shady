namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/app-preferences.ui")]
	public class AppPreferences : Gtk.Window
	{
		public bool switched_layout{ get; private set; default = false; }
		public bool auto_compile { get; private set; default = false; }

		[Signal (action=true)]
		public signal void escape_pressed();

		[GtkChild]
		private Gtk.Switch switched_layout_switch;

		[GtkChild]
		private Gtk.Switch auto_compile_switch;

		private GLib.Settings _settings;

		public AppPreferences()
		{
			_settings = new GLib.Settings("org.hasi.shady");

			escape_pressed.connect(() =>
			{
			    hide();
			});

			switched_layout = _settings.get_boolean("switched-layout");
			auto_compile = _settings.get_boolean("auto-compile");

			switched_layout_switch.set_state(switched_layout);
			auto_compile_switch.set_state(auto_compile);
		}

		[GtkCallback]
		private bool switched_layout_switch_state_set(bool state)
		{
			_settings.set_boolean("switched-layout", state);

			return false;
		}

		[GtkCallback]
		private bool auto_compile_switch_state_set(bool state)
		{
			_settings.set_boolean("auto-compile", state);

			return false;
		}

		[GtkCallback]
		private new bool hide_on_delete()
		{
			hide();

			return true;
		}
	}
}
