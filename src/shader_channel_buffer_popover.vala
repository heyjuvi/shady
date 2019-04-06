namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel-buffer-popover.ui")]
	public class ShaderChannelBufferPopover : Gtk.Popover
	{
		public signal void buffer_selected(Shader.Input input);

		private string _buffer_name = "";
		public string buffer_name
		{
		    get { return _buffer_name; }
		    set
		    {
		        if (value == "Buf A")
		        {
		            buf_a_radio_button.active = true;
		        }
		        else if (value == "Buf B")
			    {
		            buf_b_radio_button.active = true;
			    }
			    else if (value == "Buf C")
			    {
		            buf_c_radio_button.active = true;
			    }
			    else if (value == "Buf D")
			    {
		            buf_d_radio_button.active = true;
			    }

		        _buffer_name = value;
		    }
		}

		[GtkChild]
		private Gtk.RadioButton buf_a_radio_button;

		[GtkChild]
		private Gtk.RadioButton buf_b_radio_button;

		[GtkChild]
		private Gtk.RadioButton buf_c_radio_button;

		[GtkChild]
		private Gtk.RadioButton buf_d_radio_button;

		private ulong buf_a_radio_button_handler_id = 0;
		private ulong buf_b_radio_button_handler_id = 0;
		private ulong buf_c_radio_button_handler_id = 0;
		private ulong buf_d_radio_button_handler_id = 0;

		public ShaderChannelBufferPopover(Gtk.Widget relative_to)
		{
		    Object(relative_to: relative_to);

		    buf_a_radio_button_handler_id = buf_a_radio_button.toggled.connect(buf_a_radio_button_toggled);
		    buf_b_radio_button_handler_id = buf_b_radio_button.toggled.connect(buf_b_radio_button_toggled);
		    buf_c_radio_button_handler_id = buf_c_radio_button.toggled.connect(buf_c_radio_button_toggled);
		    buf_d_radio_button_handler_id = buf_d_radio_button.toggled.connect(buf_d_radio_button_toggled);
		}

		public void set_buffer_name_inconsistently(string buffer)
		{
		    SignalHandler.block(buf_a_radio_button, buf_a_radio_button_handler_id);
		    SignalHandler.block(buf_b_radio_button, buf_b_radio_button_handler_id);
		    SignalHandler.block(buf_c_radio_button, buf_c_radio_button_handler_id);
		    SignalHandler.block(buf_d_radio_button, buf_d_radio_button_handler_id);

		    buffer_name = buffer;

		    SignalHandler.unblock(buf_a_radio_button, buf_a_radio_button_handler_id);
		    SignalHandler.unblock(buf_b_radio_button, buf_b_radio_button_handler_id);
		    SignalHandler.unblock(buf_c_radio_button, buf_c_radio_button_handler_id);
		    SignalHandler.unblock(buf_d_radio_button, buf_d_radio_button_handler_id);
		}

		// TODO: this does not belong here
		public static Shader.Input generate_buffer_input(string buffer)
		{
		    Shader.Input input = new Shader.Input();

		    input.type = Shader.InputType.BUFFER;
		    input.id = ShaderEditor.SHADER_BUFFERS_ORDER[buffer];

		    return input;
		}

		public void buf_a_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				buffer_selected(generate_buffer_input("Buf A"));
				popdown();
			}
		}

		public void buf_b_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				buffer_selected(generate_buffer_input("Buf B"));
				popdown();
			}
		}

		public void buf_c_radio_button_toggled(Gtk.ToggleButton button)
		{
			if (button.active)
			{
				buffer_selected(generate_buffer_input("Buf C"));
				popdown();
			}
		}

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
