namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shadertoy-shader-item.ui")]
	public class ShadertoyShaderItem : Gtk.FlowBoxChild
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

		public string shader { get; set; default = read_file_as_string(File.new_for_uri("resource:///org/hasi/shady/data/shader/default.glsl")); }

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

		private ShaderArea _shader_area;

		public ShadertoyShaderItem()
		{
			// for some reason the shader area must not be constructed in a ui
			// file
			_shader_area = new ShaderArea(shader);
			_shader_area.set_size_request(152, 140);

			shader_container.pack_start(_shader_area, false, false);

			show_all();
		}

		public void compile() throws ShaderError
		{
			_shader_area.compile(shader);
		}
	}
}