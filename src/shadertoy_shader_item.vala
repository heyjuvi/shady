namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shadertoy-shader-item.ui")]
	public class ShadertoyShaderItem : Gtk.FlowBoxChild
	{
		private string _name;
		public string sh_it_name
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

		private int _likes;
		public int likes
		{
			get { return _likes; }
			set
			{
				likes_label.set_text(@"$value");
				_likes = value;
			}
		}

		private int _views;
		public int views
		{
			get { return _views; }
			set
			{
				views_label.set_text(@"$value");
				_views = value;
			}
		}

		public Shader shader { get; set; default = null; }

		[GtkChild]
		private Gtk.Box shader_container;

		[GtkChild]
		private Gtk.Label name_label;

		[GtkChild]
		private Gtk.Label author_label;

		[GtkChild]
		private Gtk.Label likes_label;

		[GtkChild]
		private Gtk.Label views_label;

		public ShadertoyArea _shadertoy_area;

		public ShadertoyShaderItem()
		{
			// for some reason the shader area must not be constructed in a ui
			// file

			Shader load_shader = ShaderArea.get_loading_shader();
			shader = load_shader;

			_shadertoy_area = new ShadertoyArea(load_shader);
			_shadertoy_area.set_size_request(152, 140);

            _shadertoy_area.initialized.connect(() =>
			{
				_shadertoy_area.paused = true;
			});

			shader_container.pack_start(_shadertoy_area, false, false);

			show_all();
		}

		public void compile() throws ShaderError
		{
			_shadertoy_area.compile(shader);
		}

		[GtkCallback]
		private bool on_mouse_entered(Gdk.EventCrossing event)
		{
			if (event.detail != Gdk.NotifyType.INFERIOR)
			{
				_shadertoy_area.paused = false;
			}

			return false;
		}

		[GtkCallback]
		private bool on_mouse_left(Gdk.EventCrossing event)
		{
			if (event.detail != Gdk.NotifyType.INFERIOR)
			{
				_shadertoy_area.paused = true;
			}

			return false;
		}
	}
}
