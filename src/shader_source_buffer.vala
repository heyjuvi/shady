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
		private List<Gtk.Label> _error_labels = new List<Gtk.Label>();
		private HashTable<int, string> _errors = new HashTable<int, string>(direct_hash, direct_equal);

		private Gtk.Window _error_tooltip_window;
		private Gtk.Label _error_tooltip_label;

		construct
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

			string shadertoy_glsl_search_path = shadertoy_glsl_cache.get_path();

			shadertoy_glsl_cache = shadertoy_glsl_cache.get_child("shadertoy_glsl.lang");
			shadertoy_glsl_resource.copy(shadertoy_glsl_cache, FileCopyFlags.OVERWRITE);

			Gtk.SourceLanguageManager source_language_manager = Gtk.SourceLanguageManager.get_default();
			string[] current_search_path = source_language_manager.search_path;
			current_search_path += shadertoy_glsl_search_path;
			source_language_manager.search_path = current_search_path;
		}

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
			_source_mark_attributes.icon_name = "dialog-error";

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

            view.events |= POINTER_MOTION_MASK | LEAVE_NOTIFY_MASK;

            view.motion_notify_event.connect((event_motion) =>
            {
                Gtk.TextIter iter;

                int mouse_x, mouse_y, trailing;

		        view.window_to_buffer_coords(Gtk.TextWindowType.TEXT, (int) event_motion.x, (int) event_motion.y, out mouse_x, out mouse_y);
		        view.get_iter_at_position(out iter, out trailing, mouse_x, mouse_y);

                // might not be the main window
		        Gtk.Widget toplevel = get_toplevel();

		        if (toplevel.is_toplevel())
		        {
		            _error_tooltip_window.set_transient_for(toplevel as Gtk.Window);

		            if (iter.has_tag(_error_tag))
		            {
		                Gtk.TextIter start_iter;
		                int view_x, view_y;
		                int start_iter_x, start_iter_y;
		                Gdk.Rectangle start_iter_rectangle;

		                view.translate_coordinates(toplevel, 0, 0, out view_x, out view_y);

                        buffer.get_iter_at_line(out start_iter, iter.get_line());

			            view.get_iter_location(start_iter, out start_iter_rectangle);
			            view.buffer_to_window_coords(Gtk.TextWindowType.TEXT,
			                                         start_iter_rectangle.x,
			                                         start_iter_rectangle.y,
			                                         out start_iter_x,
			                                         out start_iter_y);

			            int gutter_width = view.get_window(Gtk.TextWindowType.LEFT).get_width();

                        // it is not entirely clear, why there has to be this additional offset in the
                        // x compenent
			            _error_tooltip_window.move(view_x + gutter_width, view_y + start_iter_y - 36);
			            _error_tooltip_window.resize(view.get_allocated_width() - gutter_width, 1);

		                _error_tooltip_label.set_text(_errors[iter.get_line() + 1]);
		                _error_tooltip_window.show();
		            }
		            else
		            {
		                _error_tooltip_window.hide();
		            }
			    }

                return false;
            });

            view.leave_notify_event.connect((event_crossing) =>
            {
                _error_tooltip_window.hide();

                return false;
            });
		}

		public void clear_error_messages()
		{
			Gtk.TextIter start_iter, end_iter;

			buffer.get_bounds(out start_iter, out end_iter);

			buffer.remove_source_marks(start_iter, end_iter, "error");
			buffer.remove_tag_by_name("glsl-error-tag", start_iter, end_iter);
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

			Gtk.SourceMark new_source_mark = buffer.create_source_mark(name, "error", start_iter);

			buffer.apply_tag(_error_tag, start_iter, end_iter);

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
