namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/app-preferences.ui")]
	public class AppPreferences : Gtk.Window
	{
		public bool switched_layout { get; private set; default = false; }

		[GtkCallback]
		private bool switched_layout_switch_state_set(bool state)
		{
			switched_layout = state;

			return false;
		}

		[GtkCallback]
		private bool hide_on_delete()
		{
			hide();

			return true;
		}
	}
}
