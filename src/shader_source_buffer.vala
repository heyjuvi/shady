namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-source-buffer.ui")]
	public class ShaderSourceBuffer : Gtk.ScrolledWindow
	{
		public Gtk.SourceBuffer buffer { get; private set; }
		public ShaderSourceView view { get; private set; }

		private bool _live_mode = false;
		public bool live_mode
		{
			get { return _live_mode; }
			set
			{
				if (value)
				{
					set_policy(Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.EXTERNAL);
					_view.highlight_current_line = false;
				}
				else
				{
					set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
					view.highlight_current_line = true;
				}

				_live_mode = value;
			}
		}

		[GtkChild]
		private Gtk.Viewport viewport;

		private Gtk.SourceMarkAttributes _source_mark_attributes;

		public ShaderSourceBuffer(string buffer_name)
		{
			Gtk.SourceLanguageManager source_language_manager = Gtk.SourceLanguageManager.get_default();
			Gtk.SourceLanguage source_language = source_language_manager.get_language("glsl");

			buffer = new Gtk.SourceBuffer.with_language(source_language);

			view = new ShaderSourceView();
			view.buffer = buffer;

			viewport.add(view);

			Gdk.RGBA red = Gdk.RGBA();
			red.parse("#FF0000");

			_source_mark_attributes = new Gtk.SourceMarkAttributes();
			_source_mark_attributes.background = red;
			_source_mark_attributes.icon_name = "dialog-error";
		}

		public void clear_error_messages()
		{
			Gtk.TextIter start_iter, end_iter;

			buffer.get_bounds(out start_iter, out end_iter);

			buffer.remove_source_marks(start_iter, end_iter, "error");
		}

		public void add_error_message(int line, string name, string message)
		{
			Gtk.TextIter iter;
			buffer.get_iter_at_line(out iter, line);

			view.set_mark_attributes("error", _source_mark_attributes, 10);

			Gtk.SourceMark new_source_mark = buffer.create_source_mark(name, "error", iter);

			_source_mark_attributes.query_tooltip_text.connect((source_mark) =>
			{
				return message;
			});
		}
	}
}
