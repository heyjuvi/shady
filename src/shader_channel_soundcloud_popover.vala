namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel-soundcloud-popover.ui")]
	public class ShaderChannelSoundcloudPopover : Gtk.Popover
	{
		public signal void soundcloud_link_entered(string link);

		[GtkChild]
		private Gtk.Entry soundcloud_entry;

		public ShaderChannelSoundcloudPopover()
		{
		}

		[GtkCallback]
		private void soundcloud_entry_activated()
		{
			soundcloud_link_entered(soundcloud_entry.text);
			popdown();
		}
	}
}
