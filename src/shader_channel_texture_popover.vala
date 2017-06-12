namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel-texture-popover.ui")]
	public class ShaderChannelTexturePopover : Gtk.Popover
	{
		public signal void texture_selected(string texture_name);

		[GtkChild]
		private Gtk.FlowBox textures_box;

		public ShaderChannelTexturePopover()
		{
			foreach (string texture_id in ShadertoyResourceManager.TEXTURES.get_keys())
			{
				textures_box.add(new ShaderChannelTextureItem.from_texture(ShadertoyResourceManager.TEXTURES[texture_id]));
			}
		}
	}
}
