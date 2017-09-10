namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel-input-popover.ui")]
	public class ShaderChannelInputPopover : Gtk.Popover
	{
		public signal void input_selected(Shader.Input input);

		[GtkChild]
		private Gtk.FlowBox input_box;

		private ShaderChannelInputItem _last_selected = null;

		public ShaderChannelInputPopover(Shader.InputType input_type)
		{
			if (input_type == Shader.InputType.TEXTURE)
			{
				for (int i = 0; i < ShadertoyResourceManager.TEXTURE_IDS.length; i++)
				{
					input_box.add(new ShaderChannelInputItem.from_input(ShadertoyResourceManager.TEXTURES[i]));
				}
			}
			else if (input_type == Shader.InputType.CUBEMAP)
			{
				for (int i = 0; i < ShadertoyResourceManager.CUBEMAP_IDS.length; i++)
				{
					input_box.add(new ShaderChannelInputItem.from_input(ShadertoyResourceManager.CUBEMAPS[i]));
				}
			}

			input_box.focus.connect(() =>
			{
				input_box.unselect_all();

				return true;
			});
		}

		[GtkCallback]
		private void selected_children_changed()
		{
			if (input_box.get_selected_children().length() == 1)
			{
				ShaderChannelInputItem selected_input_item = input_box.get_selected_children().nth_data(0) as ShaderChannelInputItem;
				input_selected(selected_input_item.input);

				_last_selected = selected_input_item;

				popdown();
			}
		}
	}
}
