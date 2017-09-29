namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel-soundcloud-popover.ui")]
	public class ShaderChannelSoundcloudPopover : Gtk.Popover
	{
		public signal void soundcloud_link_entered(string link);

		[GtkChild]
		private Gtk.Entry soundcloud_entry;

		public ShaderChannelSoundcloudPopover(Gtk.Widget relative_to)
		{
			Object(relative_to: relative_to);
		}

		[GtkCallback]
		private void soundcloud_entry_activated()
		{
			soundcloud_link_entered(soundcloud_entry.text);
			popdown();
		}

		[GtkCallback]
		private void set_button_clicked()
		{
			soundcloud_link_entered(soundcloud_entry.text);
			popdown();
		}
	}
}
