namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/lang-doc-popover.ui")]
	public class LangDocPopover : Gtk.Popover
	{
	    private Core.GLSLReference _reference;
	    public Core.GLSLReference reference
	    {
	        get { return _reference; }
	        set
	        {
	            doc_label.set_markup(value.get_short_markup());
	            _reference = value;
	        }
	    }

	    [GtkChild]
	    private Gtk.Label doc_label;

		public LangDocPopover(Gtk.Widget relative_to)
		{
		    Object(relative_to: relative_to);
		}

		public LangDocPopover.new_for_reference(Core.GLSLReference reference, Gtk.Widget relative_to)
		{
		    Object(relative_to: relative_to);

		    doc_label.set_markup(reference.get_short_markup());
	        _reference = reference;
		}
	}
}
