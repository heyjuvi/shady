namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/notebook-action-widget.ui")]
	public class NotebookActionWidget : Gtk.Box
	{
	    public signal void new_buffer_clicked();
	    public signal void show_channels_clicked();

		[GtkChild]
		private Gtk.Button new_buffer_button;

		[GtkChild]
		private Gtk.Button show_channels_button;

		public NotebookActionWidget()
		{
		}

		[GtkCallback]
		private void new_buffer_button_clicked()
		{
		    new_buffer_clicked();
		}

		[GtkCallback]
		private void show_channels_button_clicked()
		{
		    show_channels_clicked();
		}
	}
}
