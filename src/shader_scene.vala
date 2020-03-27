namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-scene.ui")]
	public class ShaderScene : Gtk.Box
	{
	    private ShadertoyArea _shadertoy_area;
	    public ShadertoyArea shadertoy_area
	    {
	        get { return _shadertoy_area; }
	    }

	    public signal void fullscreen_requested();

	    [GtkChild]
	    private Gtk.Box main_shader_container;

	    [GtkChild]
	    private Gtk.Label fps_label;

	    [GtkChild]
	    private Gtk.Label time_label;

	    [GtkChild]
	    private Gtk.Label title_label;

	    [GtkChild]
	    private Gtk.Label description_label;

	    [GtkChild]
	    private Gtk.Label views_and_likes_label;

	    [GtkChild]
	    private Gtk.Label author_and_date_label;

	    [GtkChild]
	    private Gtk.TextView tags_box;

	    private Gtk.Box _placeholder_box;

	    private Shader _curr_shader;

		public ShaderScene()
		{
		    _shadertoy_area = new ShadertoyArea(ShaderArea.get_default_shader());

            _placeholder_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            _placeholder_box.get_style_context().add_class("placeholder_box");

            // TODO: it must be possible to enforce the aspect ratio in a better way
		    main_shader_container.size_allocate.connect((allocation) =>
		    {
		        _placeholder_box.height_request = (int) (allocation.width / 1.7777777777);
		        _shadertoy_area.height_request = (int) (allocation.width / 1.7777777777);
		    });

		    main_shader_container.pack_start(_shadertoy_area, false, true);

		    fps_label.draw.connect(() =>
		    {
		        StringBuilder fps = new StringBuilder();

			    fps.printf("%5.2ffps", _shadertoy_area.fps);
			    fps_label.set_label(fps.str);

			    return false;
			});

			time_label.draw.connect(() =>
			{
			    StringBuilder time = new StringBuilder();

			    time.printf("%3.2fs", _shadertoy_area.time);
			    time_label.set_label(time.str);

			    return false;
			});

		    _shadertoy_area.show();
		}

		public void compile(Shader shader)
		{
		    Gtk.TextIter start_iter, end_iter;
		    tags_box.buffer.get_iter_at_offset(out start_iter, 0);
			tags_box.buffer.get_iter_at_offset(out end_iter, -1);

		    tags_box.buffer.delete(ref start_iter, ref end_iter);

		    title_label.set_text(shader.shader_name);
		    description_label.set_text(shader.description);

		    views_and_likes_label.set_markup(@"Views: $(shader.views), Likes: $(shader.likes)");
		    author_and_date_label.set_markup(@"Created by <b>$(shader.author)</b> in $(shader.date.format("%F"))");

		    foreach (string tag in shader.tags)
			{
			    Gtk.Label tag_label = new Gtk.Label(tag);

			    Gtk.TextIter iter;
			    tags_box.buffer.get_iter_at_offset(out iter, -1);

                var anchor = tags_box.buffer.create_child_anchor(iter);
                tags_box.add_child_at_anchor(tag_label, anchor);
			    tag_label.show();
			}

		    _shadertoy_area.compile(shader);

		    _curr_shader = shader;
		}

		public void enter_fullscreen()
		{
		    main_shader_container.remove(_shadertoy_area);
		    _shadertoy_area.hide();
		    main_shader_container.pack_start(_placeholder_box, false, true);
		    _placeholder_box.show();
		}

		public void leave_fullscreen()
		{
		    // TODO: BUG UNDER GNOME WAYLOAND, FULLSCREEN WINDOW WiLL NEVER
		    // EVER UNFULLSCREEN AGAIN! EVEN AFTER CLOSING THE APPLICATION!
		    _shadertoy_area.hide();
		    main_shader_container.remove(_placeholder_box);
		    _placeholder_box.hide();
		    main_shader_container.pack_start(_shadertoy_area, false, true);
		    _shadertoy_area.show();
		}

		[GtkCallback]
		private void fullscreen_button_clicked()
		{
		    fullscreen_requested();
		}
	}
}
