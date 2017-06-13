namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel-texture-popover.ui")]
	public class ShaderChannelTexturePopover : Gtk.Popover
	{
		public signal void texture_selected(string texture_id);

		[GtkChild]
		private Gtk.FlowBox texture_box;

		private ShaderChannelTextureItem _last_selected = null;

		public ShaderChannelTexturePopover()
		{
			foreach (string texture_id in ShadertoyResourceManager.TEXTURE_IDS)
			{
				texture_box.add(new ShaderChannelTextureItem.from_texture(ShadertoyResourceManager.TEXTURES[texture_id]));
			}

			texture_box.focus.connect(() =>
			{
				texture_box.unselect_all();

				return true;
			});
		}

		[GtkCallback]
		private void selected_children_changed()
		{
			if (texture_box.get_selected_children().length() == 1)
			{
				ShaderChannelTextureItem selected_texture_item = texture_box.get_selected_children().nth_data(0) as ShaderChannelTextureItem;
				texture_selected(selected_texture_item.resource);

				_last_selected = selected_texture_item;

				popdown();
			}
		}
	}
}
