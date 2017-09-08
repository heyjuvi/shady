namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-source-buffer.ui")]
	public class ShaderSourceBuffer : Gtk.ScrolledWindow
	{
		public Gtk.SourceBuffer buffer { get; private set; }
		public ShaderSourceView view { get; private set; }

		public string name { get; set; default = null; }

		private bool _live_mode = false;
		public bool live_mode
		{
			get { return _live_mode; }
			set
			{
				if (value)
				{
					set_policy(Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.EXTERNAL);
				}
				else
				{
					set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
				}

				_live_mode = value;
			}
		}

		[GtkChild]
		private Gtk.Viewport viewport;

		private Gtk.SourceMarkAttributes _source_mark_attributes;

		private Gtk.SourceTag _error_tag;

		private List<Gtk.Label> _error_labels = new List<Gtk.Label>();

		public ShaderSourceBuffer(string buffer_name)
		{
			name = buffer_name;

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

			_error_tag = new Gtk.SourceTag("glsl-error-tag");
			_error_tag.weight = Pango.Weight.BOLD;
			_error_tag.weight_set = true;
			_error_tag.foreground = "#FFFFFF";
			_error_tag.foreground_set = true;

			buffer.tag_table.add(_error_tag);

			view.check_resize.connect(() =>
			{
				Gtk.Allocation allocation;
				view.get_allocated_size(out allocation, null);

				foreach (Gtk.Label label in _error_labels)
				{
					label.width_request = allocation.width;
				}
			});
		}

		public void clear_error_messages()
		{
			Gtk.TextIter start_iter, end_iter;

			buffer.get_bounds(out start_iter, out end_iter);

			buffer.remove_source_marks(start_iter, end_iter, "error");
		}

		public void add_error_message(int line, string name, string message)
		{
			Gtk.TextIter start_iter, end_iter;
			buffer.get_iter_at_line(out start_iter, line - 1);
			buffer.get_iter_at_line(out end_iter, line);

			view.set_mark_attributes("error", _source_mark_attributes, 10);

			Gtk.SourceMark new_source_mark = buffer.create_source_mark(name, "error", start_iter);

			_source_mark_attributes.query_tooltip_markup.connect((source_mark) =>
			{
				return message;
			});

			buffer.apply_tag(_error_tag, start_iter, end_iter);

			/*Gtk.Allocation allocation;
			view.get_allocated_size(out allocation, null);

			buffer.insert(ref end_iter, "\n", -1);
			var child_anchor = buffer.create_child_anchor(end_iter);

			var label = new Gtk.Label("Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo ");
			label.xalign = 1.0f;
			label.width_request = allocation.width;
			label.wrap = true;
			label.show();

			view.add_child_at_anchor(label, child_anchor);

			_error_labels.append(label);*/
		}
	}
}
