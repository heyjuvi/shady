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

		public ShaderSourceBuffer(string buffer_name)
		{
			Gtk.SourceLanguageManager source_language_manager = Gtk.SourceLanguageManager.get_default();
			Gtk.SourceLanguage source_language = source_language_manager.get_language("glsl");

			buffer = new Gtk.SourceBuffer.with_language(source_language);

			view = new ShaderSourceView();
			view.buffer = buffer;

			viewport.add(view);
		}
	}
}
