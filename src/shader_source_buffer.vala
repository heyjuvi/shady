namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shader-source-buffer.ui")]
	public class ShaderSourceBuffer : Gtk.ScrolledWindow
	{
		public Gtk.SourceBuffer buffer { get; private set; }
		public Gtk.SourceSearchContext search_context { get; private set; }
		public ShaderSourceView view { get; private set; }

		public string buffer_name { get; set; default = null; }

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

		private ErrorPopover _err_popover;
		private LangDocPopover _doc_popover;

		private int _error_x;
		private int _error_y;
		private int _error_width;
		private int _error_height;

		private int _mouse_x;
		private int _mouse_y;
		private int _view_x;
		private int _view_y;

		public ShaderSourceBuffer(string new_buffer_name)
		{
			buffer_name = new_buffer_name;

			GLib.Settings settings = new GLib.Settings("org.hasi.shady");
			AppPreferences.GLSLVersion glsl_version = (AppPreferences.GLSLVersion) settings.get_enum("glsl-version");
			AppPreferences.BackportingMode backporting_mode = (AppPreferences.BackportingMode) settings.get_enum("backporting");

            Gtk.SourceLanguageManager source_language_manager = Gtk.SourceLanguageManager.get_default();

			settings.changed.connect((key) =>
			{
				if (key == "glsl-version")
				{
					glsl_version = (AppPreferences.GLSLVersion) settings.get_enum("glsl-version");
				}
				else if(key == "backporting")
				{
					backporting_mode = (AppPreferences.BackportingMode) settings.get_enum("backporting");
				}

				string language_name = glsl_version.to_lang_name();
				language_name += backporting_mode.to_lang_suffix();
				Gtk.SourceLanguage source_language = source_language_manager.get_language(language_name);
				buffer.set_language(source_language);
			});

			string language_name = glsl_version.to_lang_name();
			language_name += backporting_mode.to_lang_suffix();
			Gtk.SourceLanguage source_language = source_language_manager.get_language(language_name);

			buffer = new Gtk.SourceBuffer.with_language(source_language);

			search_context = new Gtk.SourceSearchContext(buffer, null);

			view = new ShaderSourceView();
			view.buffer = buffer;

			add(view);

			_source_mark_attributes = new Gtk.SourceMarkAttributes();
			_source_mark_attributes.icon_name = "window-close-symbolic";

			_error_tag = new Gtk.SourceTag("glsl-error-tag");

			buffer.tag_table.add(_error_tag);

            _err_popover = new ErrorPopover(view);
            _doc_popover = new LangDocPopover(view);

			key_press_event.connect((widget, event) =>
			{
			    if (event.keyval == Gdk.Key.F1)
				{
				    string alphanumerics = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVXYZ1234567890_";

				    int start = buffer.cursor_position;
				    int end = buffer.cursor_position;

				    while (@"$(buffer.text[start])" in alphanumerics && start != 0) start--;
				    start++;

				    while (@"$(buffer.text[end])" in alphanumerics && end != buffer.text.length) end++;

				    if (start >= end)
				    {
				        return false;
				    }

				    Core.GLSLReferenceParser parser = new Core.GLSLReferenceParser();
				    Core.GLSLReference reference = parser.get_reference_for(@"$(buffer.text[start:end])");

                    if (reference == null)
                    {
                        return false;
                    }

                    _doc_popover.reference = reference;

                    Gtk.TextIter cursor_iter;
                    buffer.get_iter_at_offset(out cursor_iter, buffer.cursor_position);

                    Gdk.Rectangle cursor_rect;
                    view.get_iter_location(cursor_iter, out cursor_rect);

                    int win_x, win_y;
                    view.buffer_to_window_coords(Gtk.TextWindowType.LEFT,
                                                 cursor_rect.x,
                                                 cursor_rect.y,
                                                 out win_x,
                                                 out win_y);
                    cursor_rect.x = win_x;
                    cursor_rect.y = win_y;

					_doc_popover.set_pointing_to(cursor_rect);

                    _err_popover.hide();
					_doc_popover.popup();
				}

				return false;
			});

            int last_line = -1;
            buffer.notify["cursor-position"].connect(() =>
            {
                Gtk.TextIter cursor_iter;
                buffer.get_iter_at_offset(out cursor_iter, buffer.cursor_position);

                if (cursor_iter.get_line() == last_line)
                {
                    return;
                }

                last_line = cursor_iter.get_line();

                if (cursor_iter.has_tag(_error_tag))
                {
                    _err_popover.message = _errors[cursor_iter.get_line() + 1];

                    Gdk.Rectangle cursor_rect;
                    view.get_iter_location(cursor_iter, out cursor_rect);

                    int win_x, win_y;
                    view.buffer_to_window_coords(Gtk.TextWindowType.LEFT,
                                                 cursor_rect.x,
                                                 cursor_rect.y,
                                                 out win_x,
                                                 out win_y);
                    cursor_rect.x = win_x;
                    cursor_rect.y = win_y;

					_err_popover.set_pointing_to(cursor_rect);

                    _doc_popover.hide();
					_err_popover.popup();
				}
                else
                {
                    _err_popover.hide();
                }
            });
		}

		public static void initialize_resources()
		{
			for (AppPreferences.GLSLVersion version = 0; version < AppPreferences.GLSLVersion.INVALID; version += 1)
			{
				string lang_suffix = "";

				AppPreferences.BackportingMode mode_array_none[1] = {AppPreferences.BackportingMode.NONE};
				AppPreferences.BackportingMode mode_array_with_shadertoy[3] = {AppPreferences.BackportingMode.NONE,
																			   AppPreferences.BackportingMode.FULL,
																			   AppPreferences.BackportingMode.SHADERTOY};

				AppPreferences.BackportingMode mode_array_without_shadertoy[2] = {AppPreferences.BackportingMode.NONE,
																				  AppPreferences.BackportingMode.FULL};

				AppPreferences.BackportingMode mode_array[3];

				if (version == AppPreferences.GLSLVersion.GLSL_100_ES)
				{
					mode_array = mode_array_with_shadertoy;
				}
				else if (version >= AppPreferences.GLSLVersion.GLSL_150)
				{
					mode_array = mode_array_none;
				}
				else
				{
					mode_array = mode_array_without_shadertoy;
				}

				foreach (AppPreferences.BackportingMode mode in mode_array)
				{
					lang_suffix = mode.to_lang_suffix();
					string lang_filename = version.to_lang_name() + lang_suffix + ".lang";
					File shadertoy_glsl_resource = File.new_for_uri("resource:///org/hasi/shady/data/lang_specs/" + lang_filename);
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

						shadertoy_glsl_cache = shadertoy_glsl_cache.get_child(lang_filename);
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
			}
		}

		public void clear_error_messages()
		{
			Gtk.TextIter start_iter, end_iter;

			buffer.get_bounds(out start_iter, out end_iter);

			buffer.remove_source_marks(start_iter, end_iter, "error");
			buffer.remove_tag_by_name("glsl-error-tag", start_iter, end_iter);

		    _errors.remove_all();

		    _err_popover.hide();
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
