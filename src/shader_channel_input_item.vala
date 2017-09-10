namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-channel-input-item.ui")]
	public class ShaderChannelInputItem : Gtk.FlowBoxChild
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

		public Shader.Input input { get; private set; default = null; }

		[GtkChild]
		private Gtk.Label name_label;

		[GtkChild]
		private Gtk.Label author_label;

		[GtkChild]
		private Gtk.Label resolution_label;

		[GtkChild]
		private Gtk.Label channels_label;

		[GtkChild]
		private Gtk.Box shader_container;

		private ShaderArea _shader_area;

		public ShaderChannelInputItem.from_input(Shader.Input input)
		{
			_shader_area = new ShaderArea();

			shader_container.pack_start(_shader_area, true, true);

			if (input.type == Shader.InputType.TEXTURE)
			{
				int texture_width = ShadertoyResourceManager.TEXTURE_PIXBUFS[input.resource_index].width;
				int texture_height = ShadertoyResourceManager.TEXTURE_PIXBUFS[input.resource_index].height;

				int texture_channels = ShadertoyResourceManager.TEXTURE_PIXBUFS[input.resource_index].n_channels;

				chn_name = input.name;
				author = "shadertoy";
				resolution = @"$(texture_width)x$(texture_height)";
				channels = texture_channels;
			}

			this.input = input;

			_shader_area.show();

			_shader_area.initialized.connect(() =>
			{
				_shader_area.compile_shader_input_no_thread(input);
				_shader_area.compile_shader_input_no_thread(input);
			});
		}
	}
}
