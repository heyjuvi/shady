namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel-texture-item.ui")]
	public class ShaderChannelTextureItem : Gtk.FlowBoxChild
	{
		private string _name;
		public string chn_name
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
				channels_label.set_text(@"$value " + (value == 1 ? "channel" : "channels"));
				_channels = value;
			}
		}

		public Shader.Input texture_input { get; private set; default = null; }

		[GtkChild]
		private Gtk.Label name_label;

		[GtkChild]
		private Gtk.Label author_label;

		[GtkChild]
		private Gtk.Label resolution_label;

		[GtkChild]
		private Gtk.Label channels_label;

		[GtkChild]
		private Gtk.Image texture_image;

		public ShaderChannelTextureItem()
		{
		}

		public ShaderChannelTextureItem.from_texture(Shader.Input texture)
		{
			int texture_width = ShadertoyResourceManager.TEXTURE_PIXBUFS[texture.resource].width;
			int texture_height = ShadertoyResourceManager.TEXTURE_PIXBUFS[texture.resource].height;

			int texture_channels = ShadertoyResourceManager.TEXTURE_PIXBUFS[texture.resource].n_channels;

			chn_name = texture.name;
			author = "shadertoy";
			resolution = @"$(texture_width)x$(texture_height)";
			channels = texture_channels;

			this.texture_input = texture;

			int new_width = 180;

			Gdk.Pixbuf tmp_pixbuf = ShadertoyResourceManager.TEXTURE_PIXBUFS[texture.resource].copy();

			int new_height = (int) (new_width * ((float) tmp_pixbuf.height / (float) tmp_pixbuf.width));
			int dest_height = (new_height < 120 ? new_height : 120);

			tmp_pixbuf = tmp_pixbuf.scale_simple(new_width, new_height, Gdk.InterpType.BILINEAR);
			Gdk.Pixbuf dest_pixbuf = tmp_pixbuf.scale_simple(new_width, dest_height, Gdk.InterpType.BILINEAR);
			tmp_pixbuf.copy_area(0, 0, new_width, dest_height, dest_pixbuf, 0, 0);

			texture_image.pixbuf = dest_pixbuf;
		}
	}
}
