namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/error-popover.ui")]
	public class ErrorPopover : Gtk.Popover
	{
	    private string _message;
	    private string _display_message;
	    public string message
	    {
	        get { return _message; }
	        set
	        {
	            _display_message = shrink_width(value, 80);
	            err_label.set_markup(_display_message);
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

		private string shrink_width(string text, int width)
		{
		    StringBuilder tmp = new StringBuilder(text);
		    int i = 0, j = 0, last_space = 0;
		    while (i < tmp.len)
		    {
		        if (tmp.str[i] == ' ')
		        {
		            last_space = i;
		        }

		        if (tmp.str[i] == '\n')
		        {
		            j = 0;
		        }

		        if ((j + 1) % width == 0)
		        {
		            tmp.insert(last_space, "\n  ");
		            i += 3;
		            j = 3;
		        }
		        else
		        {
		            i++;
		            j++;
		        }
		    }

		    return tmp.str;
		}
	}
}
