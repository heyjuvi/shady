namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/notebook-action-widget.ui")]
	public class NotebookActionWidget : Gtk.Box
	{
		[GtkChild]
		public Gtk.Button new_buffer_button;

		[GtkChild]
		public Gtk.Button show_channels_button;

		public NotebookActionWidget()
		{
		}

		[GtkCallback]
		private void new_buffer_button_clicked()
		{
		}

		[GtkCallback]
		private void show_channels_button_clicked()
		{
		}
	}
}
