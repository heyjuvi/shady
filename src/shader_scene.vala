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

	    /*[GtkChild]
	    private Gtk.Label shader_title;

	    [GtkChild]
	    private Gtk.Label shader_description;*/

        public ShadertoyArea _fullscreen_shadertoy_area;
	    private Gtk.Window _fullscreen_window;

		public ShaderScene()
		{
		    _shadertoy_area = new ShadertoyArea();
		    _fullscreen_shadertoy_area = new ShadertoyArea();

            _fullscreen_window = new Gtk.Window();
            _fullscreen_window.width_request = 320;
            _fullscreen_window.height_request = 240;

            _fullscreen_window.delete_event.connect(() =>
            {
                return true;
            });

            _fullscreen_window.key_press_event.connect((widget, event) =>
			{
			    //bool is_fullscreen = (_fullscreen_window.get_window().get_state() & Gdk.WindowState.FULLSCREEN) == Gdk.WindowState.FULLSCREEN;

				if (event.keyval == Gdk.Key.F11 ||
				    event.keyval == Gdk.Key.Escape)
				{
					leave_fullscreen();
				}

				return false;
			});

            // TODO: it must be possible to enforce the aspect ratio in a better way
		    main_shader_container.size_allocate.connect((allocation) =>
		    {
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

			_fullscreen_window.realize();
		    _fullscreen_window.add(_fullscreen_shadertoy_area);
		}

		public void compile(Shader shader)
		{
		    _shadertoy_area.compile(shader);
		    _fullscreen_shadertoy_area.compile(shader);
		}

		public void enter_fullscreen()
		{
		    _fullscreen_window.show_all();
		    _fullscreen_window.fullscreen();
		}

		public void leave_fullscreen()
		{
		    _fullscreen_window.unfullscreen();
		    // TODO: BUG UNDER GNOME WAYLOAND, FULLSCREEN WINDOW WiLL NEVER
		    // EVER UNFULLSCREEN AGAIN! EVEN AFTER CLOSING THE APPLICATION!
		    _fullscreen_window.hide();
		}

		[GtkCallback]
		private void fullscreen_button_clicked()
		{
		    enter_fullscreen();
		}
	}
}
