namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/error-popover.ui")]
	public class ErrorPopover : Gtk.Popover
	{
	    private string _message;
	    public string message
	    {
	        get { return _message; }
	        set
	        {
	            err_label.set_markup(value);
	            _message = value;
	        }
	    }

	    [GtkChild]
	    private Gtk.Label err_label;

		public ErrorPopover(Gtk.Widget relative_to)
		{
		    Object(relative_to: relative_to);
		}

		public ErrorPopover.new_for_message(string message, Gtk.Widget relative_to)
		{
		    Object(relative_to: relative_to);

		    err_label.set_markup(message);
	        _message = message;
		}
	}
}
