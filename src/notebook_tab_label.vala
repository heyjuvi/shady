namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/notebook-tab-label.ui")]
	public class NotebookTabLabel : Gtk.Box
	{
		public string title
		{
			get { return title_label.get_text(); }
			set { title_label.set_text(value); }
		}

		public bool show_close_button
		{
			get { return close_button.get_visible(); }
			set { close_button.set_visible(value); }
		}

		public signal void close_clicked();

		[GtkChild]
		private Gtk.Label title_label;

		[GtkChild]
		private Gtk.Button close_button;

		public NotebookTabLabel()
		{
		}

		public NotebookTabLabel.with_title(string title)
		{
			title_label.set_text(title);
		}

		[GtkCallback]
		private void close_button_clicked()
		{
			close_clicked();
		}
	}
}
