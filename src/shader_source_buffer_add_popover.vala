namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-source-buffer-add-popover.ui")]
	public class ShaderSourceBufferAddPopover : Gtk.Popover
	{
		public signal void buffer_active_changed(string buffer_name, bool active);

		[GtkChild]
		private Gtk.CheckButton common_check_button;

		[GtkChild]
		private Gtk.CheckButton sound_check_button;

		[GtkChild]
		private Gtk.CheckButton buf_a_check_button;

		[GtkChild]
		private Gtk.CheckButton buf_b_check_button;

		[GtkChild]
		private Gtk.CheckButton buf_c_check_button;

		[GtkChild]
		private Gtk.CheckButton buf_d_check_button;

		[GtkChild]
		private Gtk.CheckButton cubemap_a_check_button;

		public ShaderSourceBufferAddPopover()
		{
		}

		public void set_active(string buffer_name, bool active)
		{
		    if (buffer_name == "Common")
		    {
		        common_check_button.active = active;
		    }
		    else if (buffer_name == "Sound")
		    {
		        sound_check_button.active = active;
		    }
		    else if (buffer_name == "Buf A")
		    {
		        buf_a_check_button.active = active;
		    }
		    else if (buffer_name == "Buf B")
		    {
		        buf_b_check_button.active = active;
		    }
		    else if (buffer_name == "Buf C")
		    {
		        buf_c_check_button.active = active;
		    }
		    else if (buffer_name == "Buf D")
		    {
		        buf_d_check_button.active = active;
		    }
		    else if (buffer_name == "Cubemap A")
		    {
		        cubemap_a_check_button.active = active;
		    }
		}

		[GtkCallback]
		public void common_check_button_toggled(Gtk.ToggleButton button)
		{
			buffer_active_changed("Common", button.active);
		}

		[GtkCallback]
		public void sound_check_button_toggled(Gtk.ToggleButton button)
		{
			buffer_active_changed("Sound", button.active);
		}

		[GtkCallback]
		public void buf_a_check_button_toggled(Gtk.ToggleButton button)
		{
			buffer_active_changed("Buf A", button.active);
		}

		[GtkCallback]
		public void buf_b_check_button_toggled(Gtk.ToggleButton button)
		{
			buffer_active_changed("Buf B", button.active);
		}

		[GtkCallback]
		public void buf_c_check_button_toggled(Gtk.ToggleButton button)
		{
			buffer_active_changed("Buf C", button.active);
		}

		[GtkCallback]
		public void buf_d_check_button_toggled(Gtk.ToggleButton button)
		{
			buffer_active_changed("Buf D", button.active);
		}

		[GtkCallback]
		public void cubemap_a_check_button_toggled(Gtk.ToggleButton button)
		{
			buffer_active_changed("Cubemap A", button.active);
		}
	}
}
