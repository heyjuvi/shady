namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-source-buffer.ui")]
	public class ShaderSourceBuffer : Gtk.ScrolledWindow
	{
		public Gtk.SourceBuffer buffer { get; private set; }
		public ShaderSourceView view { get; private set; }

		public string buf_name { get; set; default = null; }

		private bool _live_mode = false;
		public bool live_mode
		{
			get { return _live_mode; }
			set
			{
				if (value)
				{
					set_policy(Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.EXTERNAL);
				}
				else
				{
					set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
				}

				_live_mode = value;
			}
		}

		private Gtk.SourceMarkAttributes _source_mark_attributes;

		private Gtk.SourceTag _error_tag;
		private HashTable<int, string> _errors = new HashTable<int, string>(direct_hash, direct_equal);

		private Gtk.Window _error_tooltip_window;
		private Gtk.Label _error_tooltip_label;

		private int _error_x;
		private int _error_y;
		private int _error_width;
		private int _error_height;

		public ShaderSourceBuffer(string buffer_name)
		{
			buf_name = buffer_name;

            Gtk.SourceLanguageManager source_language_manager = Gtk.SourceLanguageManager.get_default();
			Gtk.SourceLanguage source_language = source_language_manager.get_language("shadertoy_glsl");

			buffer = new Gtk.SourceBuffer.with_language(source_language);

			view = new ShaderSourceView();
			view.buffer = buffer;

			add(view);

			_source_mark_attributes = new Gtk.SourceMarkAttributes();
			_source_mark_attributes.icon_name = "window-close-symbolic";

			_error_tag = new Gtk.SourceTag("glsl-error-tag");

			buffer.tag_table.add(_error_tag);

			_error_tooltip_window = new Gtk.Window(Gtk.WindowType.POPUP);
            _error_tooltip_window.window_position = Gtk.WindowPosition.NONE;
            _error_tooltip_window.get_style_context().add_class("error_tooltip");

            view.set_tooltip_window(_error_tooltip_window);

            _error_tooltip_label = new Gtk.Label("");
            _error_tooltip_label.xalign = 0.0f;
            _error_tooltip_label.show();

            _error_tooltip_window.add(_error_tooltip_label);

            view.events |= POINTER_MOTION_MASK;
            _error_tooltip_window.events |= ENTER_NOTIFY_MASK;

            buffer.notify["cursor-position"].connect(() =>
            {
                Gtk.TextIter iter;

                buffer.get_iter_at_offset(out iter, buffer.cursor_position);

                if (iter.has_tag(_error_tag))
                {
                    show_error(iter.get_line());
                }
                else
                {
                    hide_error();
                }
            });

            view.motion_notify_event.connect((event_motion) =>
            {
                // might not be the main window
	            Gtk.Widget toplevel = get_toplevel();

	            if (toplevel.is_toplevel())
	            {
	                Gtk.TextIter iter, cursor_iter;

                    int mouse_x, mouse_y, trailing;
                    int view_x, view_y;

                    view.translate_coordinates(toplevel, 0, 0, out view_x, out view_y);
                    //print(@"$view_x, $view_y\n");

	                view.window_to_buffer_coords(Gtk.TextWindowType.TEXT, (int) event_motion.x, (int) event_motion.y, out mouse_x, out mouse_y);
	                view.get_iter_at_position(out iter, out trailing, mouse_x, mouse_y);

	                buffer.get_iter_at_offset(out cursor_iter, buffer.cursor_position);

                    if (!over_error(mouse_x + view_x, mouse_y + view_y) && cursor_iter.has_tag(_error_tag))
	                {
	                    if (!_error_tooltip_window.visible)
	                    {
	                        show_error(cursor_iter.get_line());
	                    }
	                }
	            }

                return false;
            });

            size_allocate.connect((allocation) =>
            {
                if (_error_tooltip_window.visible)
                {
                    Gtk.TextIter iter;

                    buffer.get_iter_at_offset(out iter, buffer.cursor_position);

                    show_error(iter.get_line());
                }
            });

            _error_tooltip_window.enter_notify_event.connect((event_crossing) =>
            {
                _error_tooltip_window.hide();

                return false;
            });
		}

		public static void initialize_resources()
		{
		    File shadertoy_glsl_resource = File.new_for_uri("resource:///org/hasi/shady/data/lang_specs/shadertoy_glsl.lang");
			File shadertoy_glsl_cache = File.new_for_path(Environment.get_home_dir());

			shadertoy_glsl_cache = shadertoy_glsl_cache.get_child(".cache").get_child("shady");

            if (!shadertoy_glsl_cache.query_exists())
            {
			    try
			    {
			        shadertoy_glsl_cache.make_directory_with_parents();
			    }
			    catch (Error e)
			    {
			        print(@"Error while creating ~/.cache/shady: $(e.message)");
			    }
			}

            try
            {
			    string shadertoy_glsl_search_path = shadertoy_glsl_cache.get_path();

			    shadertoy_glsl_cache = shadertoy_glsl_cache.get_child("shadertoy_glsl.lang");
			    shadertoy_glsl_resource.copy(shadertoy_glsl_cache, FileCopyFlags.OVERWRITE);

			    Gtk.SourceLanguageManager source_language_manager = Gtk.SourceLanguageManager.get_default();
                string[] current_search_path = source_language_manager.search_path;
			    current_search_path += shadertoy_glsl_search_path;
			    source_language_manager.search_path = current_search_path;
			}
			catch (Error e)
			{
			    print(@"Could not initialize resources for shader source buffer: $(e.message)\n");
			}
		}

		private bool over_error(int x, int y)
		{
            if (x > _error_x &&
                x < _error_x + _error_width &&
                y > _error_y &&
                y < _error_y + _error_height)
            {
                return true;
            }

		    return false;
		}

		private void show_error(int line)
		{
            // might not be the main window
	        Gtk.Widget toplevel = get_toplevel();

	        if (toplevel.is_toplevel())
	        {
	            _error_tooltip_window.set_transient_for(toplevel as Gtk.Window);

                Gtk.TextIter start_iter;
                int view_x, view_y;
                int start_iter_x, start_iter_y;
                Gdk.Rectangle start_iter_rectangle;

                view.translate_coordinates(toplevel, 0, 0, out view_x, out view_y);

                buffer.get_iter_at_line(out start_iter, line);

	            view.get_iter_location(start_iter, out start_iter_rectangle);
	            view.buffer_to_window_coords(Gtk.TextWindowType.TEXT,
	                                         start_iter_rectangle.x,
	                                         start_iter_rectangle.y,
	                                         out start_iter_x,
	                                         out start_iter_y);

	            int gutter_width = view.get_window(Gtk.TextWindowType.LEFT).get_width();

                // it is not entirely clear, why there has to be this additional offset in the
                // x compenent
                _error_tooltip_label.set_text(_errors[line + 1]);

                _error_tooltip_window.resize(view.get_allocated_width() - gutter_width, 1);
                _error_tooltip_window.show();
                _error_tooltip_window.move(view_x + gutter_width,
	                                       view_y + start_iter_y - _error_tooltip_window.get_allocated_height());

	            _error_tooltip_window.get_position(out _error_x, out _error_y);
                _error_tooltip_window.get_size(out _error_width, out _error_height);
		    }
		}

		private void hide_error()
		{
		    _error_tooltip_window.hide();
		}

		public void clear_error_messages()
		{
			Gtk.TextIter start_iter, end_iter;

			buffer.get_bounds(out start_iter, out end_iter);

			buffer.remove_source_marks(start_iter, end_iter, "error");
			buffer.remove_tag_by_name("glsl-error-tag", start_iter, end_iter);

		    _errors.remove_all();
		}

		public void add_error_message(int line, string name, string message)
		{
		    if (!(line in _errors))
		    {
		        _errors.insert(line, message);
		    }

			Gtk.TextIter start_iter, end_iter;
			buffer.get_iter_at_line(out start_iter, line - 1);
			buffer.get_iter_at_line(out end_iter, line);

			view.set_mark_attributes("error", _source_mark_attributes, 10);

			buffer.create_source_mark(name, "error", start_iter);

			buffer.apply_tag(_error_tag, start_iter, end_iter);

			Gtk.TextIter cursor_iter;
            buffer.get_iter_at_offset(out cursor_iter, buffer.cursor_position);

            if (cursor_iter.has_tag(_error_tag))
            {
                show_error(cursor_iter.get_line());
            }

			/*Gtk.Allocation allocation;
			view.get_allocated_size(out allocation, null);

			buffer.insert(ref end_iter, "\n", -1);
			var child_anchor = buffer.create_child_anchor(end_iter);

			var label = new Gtk.Label("Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo Yoooo ");
			label.xalign = 1.0f;
			label.width_request = allocation.width;
			label.wrap = true;
			label.show();

			view.add_child_at_anchor(label, child_anchor);

			_error_labels.append(label);*/
		}
	}
}
