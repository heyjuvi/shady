namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel-input-popover.ui")]
	public class ShaderChannelInputPopover : Gtk.Popover
	{
		public signal void input_selected(Shader.Input input);

		[GtkChild]
		private Gtk.FlowBox input_box;

		private ShaderChannelInputItem _last_selected = null;

		public ShaderChannelInputPopover(Shader.InputType input_type, Gtk.Widget relative_to)
		{
			Object(relative_to: relative_to);

			if (input_type == Shader.InputType.TEXTURE)
			{
				for (int i = 0; i < ShadertoyResourceManager.TEXTURES.length; i++)
				{
					input_box.add(new ShaderChannelInputItem.from_input(ShadertoyResourceManager.TEXTURES[i]));
				}
			}
			else if (input_type == Shader.InputType.CUBEMAP)
			{
				for (int i = 0; i < ShadertoyResourceManager.CUBEMAPS.length; i++)
				{
					input_box.add(new ShaderChannelInputItem.from_input(ShadertoyResourceManager.CUBEMAPS[i]));
				}
			}
			else if (input_type == Shader.InputType.3DTEXTURE)
			{
				for (int i = 0; i < ShadertoyResourceManager.3DTEXTURES.length; i++)
				{
					input_box.add(new ShaderChannelInputItem.from_input(ShadertoyResourceManager.3DTEXTURES[i]));
				}
			}

			input_box.focus.connect(() =>
			{
				//input_box.unselect_all();

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

				print(@"The window is $((int) get_window())\n\n");
				//popdown();
			}
		}
	}
}
