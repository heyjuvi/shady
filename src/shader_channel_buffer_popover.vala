namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel-buffer-popover.ui")]
	public class ShaderChannelBufferPopover : Gtk.Popover
	{
		public signal void buffer_selected(Shader.Input input);

		public ShaderChannelBufferPopover(Gtk.Widget relative_to)
		{
		    Object(relative_to: relative_to);
		}

		private Shader.Input generate_buffer_input(string buffer)
		{
		    Shader.Input input = new Shader.Input();

		    input.type = Shader.InputType.BUFFER;
		    input.id = ShaderEditor.SHADER_BUFFERS_ORDER[buffer];

		    return input;
		}

		[GtkCallback]
		public void buf_a_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				buffer_selected(generate_buffer_input("Buf A"));
				popdown();
			}
		}

		[GtkCallback]
		public void buf_b_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				buffer_selected(generate_buffer_input("Buf B"));
				popdown();
			}
		}

		[GtkCallback]
		public void buf_c_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				buffer_selected(generate_buffer_input("Buf C"));
				popdown();
			}
		}

		[GtkCallback]
		public void buf_d_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				buffer_selected(generate_buffer_input("Buf D"));
				popdown();
			}
		}
	}
}
