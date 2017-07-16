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

		private ShaderArea _shader_area;

		public ShadertoyShaderItem()
		{
			// for some reason the shader area must not be constructed in a ui
			// file
			string load_code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/load.glsl", 0).get_data());

			Shader load_shader = new Shader();

			Shader.Renderpass renderpass = new Shader.Renderpass();

			renderpass.code = load_code;
			renderpass.type = Shader.RenderpassType.IMAGE;

			load_shader.renderpasses.append_val(renderpass);

			_shader_area = new ShaderArea(load_shader);
			_shader_area.set_size_request(152, 140);
			_shader_area.pause(true);

			shader_container.pack_start(_shader_area, false, false);
			/*Gtk.Button bla = new Gtk.Button();
			bla.set_size_request(152, 140);
			shader_container.pack_start(bla, false, false);*/

			show_all();
		}

		public void compile() throws ShaderError
		{
			_shader_area.compile(shader);
		}

		[GtkCallback]
		private bool on_mouse_entered(Gdk.EventCrossing event)
		{
			if (event.detail != Gdk.NotifyType.INFERIOR)
			{
				_shader_area.reset_time();
				_shader_area.pause(false);
			}

			return false;
		}

		[GtkCallback]
		private bool on_mouse_left(Gdk.EventCrossing event)
		{
			if (event.detail != Gdk.NotifyType.INFERIOR)
			{
				_shader_area.reset_time();
				_shader_area.pause(true);
			}

			return false;
		}
	}
}
