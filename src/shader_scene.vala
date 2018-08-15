namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-scene.ui")]
	public class ShaderScene : Gtk.Box
	{
	    private ShaderManager _shader_manager;
	    public ShaderManager shader_manager
	    {
	        get { return _shader_manager; }
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

        public ShaderManager _fullscreen_shader_manager;
	    private Gtk.Window _fullscreen_window;

		public ShaderScene()
		{
		    _shader_manager = new ShaderManager();
		    _fullscreen_shader_manager = new ShaderManager();

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
		        _shader_manager.height_request = (int) (allocation.width / 1.7777777777);
		    });

		    main_shader_container.pack_start(_shader_manager, false, true);

		    fps_label.draw.connect(() =>
		    {
		        StringBuilder fps = new StringBuilder();

			    fps.printf("%5.2ffps", _shader_manager.fps);
			    fps_label.set_label(fps.str);

			    return false;
			});

			time_label.draw.connect(() =>
			{
			    StringBuilder time = new StringBuilder();

			    time.printf("%3.2fs", _shader_manager.time);
			    time_label.set_label(time.str);

			    return false;
			});

		    _shader_manager.show();

			_fullscreen_window.realize();
		    _fullscreen_window.add(_fullscreen_shader_manager);
		}

		public void compile(Shader shader)
		{
		    _shader_manager.compile(shader);
		    _fullscreen_shader_manager.compile(shader);
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
