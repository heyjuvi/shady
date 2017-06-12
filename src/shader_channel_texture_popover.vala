namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel-texture-popover.ui")]
	public class ShaderChannelTexturePopover : Gtk.Popover
	{
		public signal void texture_selected(string texture_name);

		public ShaderChannelTexturePopover()
		{
		}
	}
}
