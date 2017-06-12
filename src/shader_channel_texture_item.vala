namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel-texture-item.ui")]
	public class ShaderChannelTextureItem : Gtk.FlowBoxChild
	{
		private string _name;
		public string name
		{
			get { return _name; }
			set
			{
				name_label.set_text(value);
				_name = value;
			}
		}

		private string _author;
		public string author
		{
			get { return _author; }
			set
			{
				author_label.set_text(value);
				_author = value;
			}
		}

		private string _resolution;
		public string resolution
		{
			get { return _resolution; }
			set
			{
				resolution_label.set_text(@"$value");
				_resolution = value;
			}
		}

		private int _channels;
		public int channels
		{
			get { return _channels; }
			set
			{
				channels_label.set_text(@"$value" + (value == 1 ? "channel" : "channels"));
				_channels = value;
			}
		}

		[GtkChild]
		private Gtk.Label name_label;

		[GtkChild]
		private Gtk.Label author_label;

		[GtkChild]
		private Gtk.Label resolution_label;

		[GtkChild]
		private Gtk.Label channels_label;

		public ShaderChannelTextureItem()
		{
		}
	}
}
