namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/notebook-action-widget.ui")]
	public class NotebookActionWidget : Gtk.Box
	{
	    public signal void buffer_active_changed(string buffer_name, bool active);
	    public signal void show_channels_clicked();

	    [GtkChild]
	    private ShaderSourceBufferAddPopover source_buffer_add_popover;

		public NotebookActionWidget()
		{
		}

		public void set_buffer_active(string buffer_name, bool active)
		{
		    source_buffer_add_popover.set_active(buffer_name, active);
		}

        [GtkCallback]
		private void source_buffer_add_popover_buffer_active_changed(string buffer_name, bool active)
		{
		    buffer_active_changed(buffer_name, active);
		}

		[GtkCallback]
		private void show_channels_button_clicked()
		{
		    show_channels_clicked();
		}

	}
}
