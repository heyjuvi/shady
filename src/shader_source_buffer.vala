namespace Shady
{
    [GtkTemplate (ui = "/org/hasi/shady/ui/shader-source-buffer-line-error.ui")]
    private class ShaderSourceBufferLineError : Gtk.Label
    {
        public Gtk.TextChildAnchor label_anchor;

        public int corresponding_line;

        public ShaderSourceBufferLineError(string label)
        {
            set_text(label);
        }

        public int get_line(Gtk.TextBuffer buffer)
        {
            Gtk.TextIter iter;
		    buffer.get_iter_at_child_anchor(out iter, label_anchor);

		    return iter.get_line();
        }

        public void get_start_iter(Gtk.TextBuffer buffer, out Gtk.TextIter iter)
        {
            buffer.get_iter_at_child_anchor(out iter, label_anchor);
        }

        public void get_end_iter(Gtk.TextBuffer buffer, out Gtk.TextIter iter)
        {
            buffer.get_iter_at_child_anchor(out iter, label_anchor);
            iter.forward_char();
        }
	}

    private class ShaderSourceGutterRenderer : Gtk.SourceGutterRendererText
    {
        public unowned List<ShaderSourceBufferLineError> errors;

        public ShaderSourceGutterRenderer()
        {
            xpad = 0;
            xalign = 1;
        }

        public override void query_data(Gtk.TextIter start,
                                        Gtk.TextIter end,
                                        Gtk.SourceGutterRendererState state)
        {
            Gtk.TextIter cursor_iter;
			view.buffer.get_iter_at_offset(out cursor_iter, view.buffer.cursor_position);

            bool do_not_draw = false;
            int errors_before_line = 0;
            foreach (ShaderSourceBufferLineError error in errors)
            {
                Gtk.TextIter error_start, error_end;
                error.get_start_iter(view.buffer, out error_start);
                error.get_end_iter(view.buffer, out error_end);

                error_start.forward_char();

                if (start.get_line() == error.get_line(view.buffer))
                {
                    do_not_draw = true;
                }

                if (start.compare(error_start) > 0)
                {
                    errors_before_line++;
                }
            }

            string bare_text = @"$(start.get_line() - errors_before_line + 1) ";
            if (!do_not_draw)
            {
                if (start.get_line() == cursor_iter.get_line())
                {
                    markup = @"<b>$bare_text</b>";
                }
                else
                {
                    markup = bare_text;
                }
            }
            else
            {
                markup = "";
            }

            Gtk.Label label = new Gtk.Label("0");

            Pango.Layout layout = label.get_layout();
            layout.set_markup("0", markup.length);

            int width, height;
            layout.get_pixel_size(out width, out height);

            size = bare_text.length * width;
        }
    }

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

		[GtkChild]
		private Gtk.Viewport viewport;

		private Gtk.SourceMarkAttributes _source_mark_attributes;

		private Gtk.SourceTag _error_tag;

        private ShaderSourceGutterRenderer _gutter_renderer;
		private List<ShaderSourceBufferLineError> _errors;

		private Gtk.TextIter _last_cursor_iter;
		private bool _no_delete;

		public ShaderSourceBuffer(string buffer_name)
		{
			buf_name = buffer_name;

			Gtk.SourceLanguageManager source_language_manager = Gtk.SourceLanguageManager.get_default();
			Gtk.SourceLanguage source_language = source_language_manager.get_language("glsl");

			buffer = new Gtk.SourceBuffer.with_language(source_language);
			//buffer.max_undo_levels = 0;

			view = new ShaderSourceView();
			view.buffer = buffer;

			_gutter_renderer = new ShaderSourceGutterRenderer();
		    _errors = new List<ShaderSourceBufferLineError>();

		    _gutter_renderer.errors = _errors;
		    _gutter_renderer.visible = true;

			Gtk.SourceGutter gutter = view.get_gutter(Gtk.TextWindowType.LEFT);
            gutter.insert(_gutter_renderer, 0);

			viewport.add(view);

			Gdk.RGBA red = Gdk.RGBA();
			red.parse("#FF0000");

			_source_mark_attributes = new Gtk.SourceMarkAttributes();
			_source_mark_attributes.background = red;
			_source_mark_attributes.icon_name = "dialog-error";

			_error_tag = new Gtk.SourceTag("glsl-error-tag");
			_error_tag.weight = Pango.Weight.BOLD;
			_error_tag.weight_set = true;
			_error_tag.foreground = "#FFFFFF";
			_error_tag.foreground_set = true;

			buffer.tag_table.add(_error_tag);

			view.check_resize.connect(() =>
			{
				Gtk.Allocation allocation;
				view.get_allocated_size(out allocation, null);

				foreach (ShaderSourceBufferLineError line_error in _errors)
				{
					line_error.width_request = allocation.width - 64;
				}
			});

            view.buffer.get_start_iter(out _last_cursor_iter);

            buffer.undo.connect(() =>
            {
                _no_delete = true;
            });

            _no_delete = false;
			view.buffer.delete_range.connect((start_iter, end_iter) =>
			{
			    if (_no_delete)
			    {
			        _no_delete = false;
			        print("yes!!\n");
			        return;
			    }

			    Gtk.TextIter cursor_iter;
			    view.buffer.get_iter_at_offset(out cursor_iter, view.buffer.cursor_position);

			    foreach (ShaderSourceBufferLineError line_error in _errors)
			    {
			        Gtk.TextIter iter, after_iter;
			        line_error.get_start_iter(view.buffer, out iter);
			        line_error.get_end_iter(view.buffer, out after_iter);
			        //after_iter.forward_chars(1);

			        if (cursor_iter.compare(start_iter) <= 0)
			        {
			            if (start_iter.compare(iter) <= 0 && end_iter.compare(iter) >= 0)
			            {
			                if (end_iter.compare(after_iter) >= 0)
			                {
			                    end_iter = start_iter;
			                }
			                else
			                {
			                    Gtk.TextIter begin_of_from_line;
                                Gtk.TextIter end_of_from_line, end_of_to_line;

                                view.buffer.get_iter_at_line_offset(out begin_of_from_line, after_iter.get_line() + 1, 0);
                                view.buffer.get_iter_at_line_offset(out end_of_from_line, after_iter.get_line() + 1, int.MAX);

			                    string move_text = view.buffer.get_text(begin_of_from_line, end_of_from_line, false);
			                    end_of_from_line.forward_char();

			                    view.buffer.get_iter_at_line_offset(out end_of_to_line, after_iter.get_line() - 1, int.MAX);
			                    view.buffer.insert(ref end_of_to_line, move_text, move_text.length);

			                    // back to old position
			                    end_of_to_line.backward_chars(move_text.length);

			                    // new valid iter again, please
			                    line_error.get_end_iter(view.buffer, out after_iter);

			                    // get valid iters again for the final deleting by the ecosystem
			                    view.buffer.get_iter_at_line_offset(out start_iter, after_iter.get_line() + 1, 0);
                                view.buffer.get_iter_at_line_offset(out end_iter, after_iter.get_line() + 1, int.MAX);
                                end_iter.forward_char();

			                    view.buffer.place_cursor(end_of_to_line);
			                }
			            }
			        }
			        else if (cursor_iter.compare(end_iter) >= 0)
			        {
			            if (start_iter.compare(after_iter) <= 0 && end_iter.compare(after_iter) >= 0)
			            {
			                if (start_iter.compare(iter) <= 0)
			                {
			                    start_iter = end_iter;
			                }
			                else
			                {
                                Gtk.TextIter begin_of_from_line;
                                Gtk.TextIter end_of_from_line, end_of_to_line;

                                view.buffer.get_iter_at_line_offset(out begin_of_from_line, after_iter.get_line() + 1, 0);

                                view.buffer.get_iter_at_line_offset(out end_of_from_line, after_iter.get_line() + 1, int.MAX);
                                view.buffer.get_iter_at_line_offset(out end_of_to_line, after_iter.get_line() - 1, int.MAX);

			                    string move_text = view.buffer.get_text(begin_of_from_line, end_of_from_line, false);

			                    //((Gtk.SourceBuffer) view.buffer).begin_user_action();
			                    if (move_text.strip().length != 0)
			                    {
			                        view.buffer.insert(ref end_of_to_line, move_text, move_text.length);
			                    }
			                    //((Gtk.SourceBuffer) view.buffer).end_user_action();

			                    // back to old position
			                    end_of_to_line.backward_chars(move_text.length);
                                view.buffer.place_cursor(end_of_to_line);

                                // new valid iter again, please
			                    line_error.get_end_iter(view.buffer, out after_iter);

                                Gtk.TextIter start_delete_iter, end_delete_iter;
                                //view.buffer.get_iter_at_line_offset(out start_delete_iter, after_iter.get_line(), int.MAX);
                                view.buffer.get_iter_at_line_offset(out end_delete_iter, after_iter.get_line() + 1, int.MAX);
                                start_delete_iter = after_iter;

                                string foo = view.buffer.get_text(start_delete_iter, end_delete_iter, false);
                                print("deleting aaa" + foo + "aaa\n\n\n");

                                //((Gtk.SourceBuffer) view.buffer).begin_user_action();
                                //start_delete_iter.backward_char();
                                if (foo.strip().length == 0)
                                {
                                    print("works\n");
                                    view.buffer.delete(ref start_delete_iter, ref end_delete_iter);

                                    // new valid iter again, please
			                        line_error.get_end_iter(view.buffer, out after_iter);
			                        //after_iter.forward_char();

                                    view.buffer.get_iter_at_line_offset(out start_iter, after_iter.get_line() + 1, 0);
                                    view.buffer.get_iter_at_line_offset(out end_iter, after_iter.get_line() + 1, 0);
                                    start_iter.backward_char();
                                }
                                else
                                {
                                    print("with text\n");
                                    view.buffer.delete(ref start_delete_iter, ref end_delete_iter);

                                    // new valid iter again, please
			                        line_error.get_end_iter(view.buffer, out after_iter);

                                    view.buffer.get_iter_at_line_offset(out start_iter, after_iter.get_line() + 1, 0);
                                    view.buffer.get_iter_at_line_offset(out end_iter, after_iter.get_line() + 1, 0);
                                    //start_iter.backward_char();
                                }
			                }
			            }
			        }
			    }
			});

			view.buffer.insert_text.connect((ref iter, text, length) =>
			{
			    print("inserted aaa" + text + "aaa\n\n\n");
			});

			/*view.buffer.notify["cursor-position"].connect(() =>
			{
			    Gtk.TextIter cursor_iter;
			    view.buffer.get_iter_at_offset(out cursor_iter, view.buffer.cursor_position);

			    foreach (ShaderSourceBufferLineError line_error in _errors)
			    {
			        Gtk.TextIter iter, after_iter;
			        line_error.get_start_iter(view.buffer, out iter);
			        line_error.get_end_iter(view.buffer, out after_iter);
			        //after_iter.forward_chars(1);

		            int cursor_movement = cursor_iter.compare(_last_cursor_iter);

		            if (cursor_movement == 0)
		            {
		                break;
		            }

		            if (cursor_iter.compare(iter) == 0)
		            {
		                Gtk.TextIter test_iter = _last_cursor_iter;
		                test_iter.forward_chars(1);

		                if (test_iter.compare(iter) == 0 && cursor_movement > 0)
		                {
		                    iter.forward_chars(2);
		                    view.buffer.place_cursor(iter);

		                    continue;
		                }
		            }

		            if (cursor_iter.compare(after_iter) == 0)
		            {
		                Gtk.TextIter test_iter = _last_cursor_iter;
		                test_iter.backward_chars(1);

		                if (test_iter.compare(after_iter) == 0 && cursor_movement < 0)
		                {
		                    iter.backward_chars(1);
		                    view.buffer.place_cursor(iter);

		                    continue;
		                }
		            }


		            if (cursor_iter.compare(iter) == 0 || cursor_iter.compare(after_iter) == 0)
		            {
		                if (cursor_movement > 0)
		                {
		                    Gtk.TextIter test_iter = _last_cursor_iter;
		                    view.buffer.get_iter_at_line_offset(out test_iter, _last_cursor_iter.get_line(), 0);

		                    int i = 0;
		                    while (test_iter.compare(_last_cursor_iter) != 0)
		                    {
		                        view.buffer.get_iter_at_line_offset(out test_iter, _last_cursor_iter.get_line(), i);
		                        i++;
		                    }

                            cursor_iter.forward_line();
		                    view.buffer.get_iter_at_line_offset(out cursor_iter, cursor_iter.get_line(), i - 1 < 0 ? 0 : i - 1);
		                    view.buffer.place_cursor(cursor_iter);

		                    continue;
		                }
		            }

		            if (cursor_iter.compare(iter) == 0 || cursor_iter.compare(after_iter) == 0)
		            {
		                if (cursor_movement < 0)
		                {
		                    Gtk.TextIter test_iter;
		                    view.buffer.get_iter_at_line_offset(out test_iter, _last_cursor_iter.get_line(), 0);

		                    int i = 0;
		                    while (test_iter.compare(_last_cursor_iter) != 0)
		                    {
		                        view.buffer.get_iter_at_line_offset(out test_iter, _last_cursor_iter.get_line(), i);
		                        i++;
		                    }

		                    cursor_iter.backward_line();
		                    view.buffer.get_iter_at_line_offset(out cursor_iter, cursor_iter.get_line(), i - 1 < 0 ? 0 : i - 1);
		                    view.buffer.place_cursor(cursor_iter);

		                    continue;
		                }
		            }
		        }

			    _last_cursor_iter = cursor_iter;
			});*/
		}

		public void clear_error_messages()
		{
			/*Gtk.TextIter start_iter, end_iter;

			buffer.get_bounds(out start_iter, out end_iter);

			buffer.remove_source_marks(start_iter, end_iter, "error");*/
		}

		public void add_error_message(int line, string name, string message)
		{
			Gtk.TextIter start_iter, end_iter;
			buffer.get_iter_at_line(out start_iter, line - 1);
			buffer.get_iter_at_line(out end_iter, line);

			view.set_mark_attributes("error", _source_mark_attributes, 10);

			//Gtk.SourceMark new_source_mark = buffer.create_source_mark(name, "error", start_iter);

			/*_source_mark_attributes.query_tooltip_markup.connect((source_mark) =>
			{
				return message;
			});

			buffer.apply_tag(_error_tag, start_iter, end_iter);*/

			Gtk.Allocation allocation;
			view.get_allocated_size(out allocation, null);

			//buffer.insert(ref end_iter, "\n", -1);
			end_iter.backward_char();

            bool line_occupied = false;
            foreach (ShaderSourceBufferLineError le in _errors)
            {
			    if (end_iter.get_line() == le.corresponding_line)
                {
                    line_occupied = true;
                }
            }

            if (!line_occupied)
            {
		        ShaderSourceBufferLineError line_error = new ShaderSourceBufferLineError(@"Line $line ($name): $message");
		        line_error.corresponding_line = end_iter.get_line();

		        line_error.xalign = 0.0f;
		        line_error.width_request = allocation.width - 64;
		        line_error.wrap = true;

		        /*line_error.dummy = new Gtk.Label("");

		        line_error.dummy_anchor = buffer.create_child_anchor(end_iter);
                view.add_child_at_anchor(line_error.dummy, line_error.dummy_anchor);*/

                buffer.get_iter_at_line_offset(out end_iter, line, 0);
                //end_iter.backward_char();

                line_error.label_anchor = buffer.create_child_anchor(end_iter);

                ((Gtk.SourceBuffer) view.buffer).begin_not_undoable_action();

		        view.add_child_at_anchor(line_error, line_error.label_anchor);
			    line_error.get_end_iter(view.buffer, out end_iter);

			    view.buffer.insert(ref end_iter, "\n", 1);
		        line_error.show();

		        ((Gtk.SourceBuffer) view.buffer).end_not_undoable_action();

		        _errors.append(line_error);
		        _gutter_renderer.errors =_errors;
		    }
		}
	}
}
