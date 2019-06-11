namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shadertoy-search-dialog.ui")]
	public class ShadertoySearchDialog : Gtk.Dialog
	{
		public Shader selected_shader { get; private set; default = null; }

		[GtkChild]
		private Gtk.SearchEntry shadertoy_search_entry;

		[GtkChild]
		private Gtk.Button load_shader_button;

		[GtkChild]
		private Gtk.Stack content_stack;

		[GtkChild]
		private Gtk.Label loading_label;

		[GtkChild]
		private Gtk.FlowBox shader_box;

		private int _last_index = 0;
		private string _current_child = "content";

		private Shader?[] _found_shaders = null;

		private bool _destroyed;

		construct
		{
			// it is not so super clear, why this cannot be set in the ui file
			this.use_header_bar = 1;
		}

		public ShadertoySearchDialog(Gtk.Window parent)
		{
			set_transient_for(parent);

			content_stack.visible_child_name = "content";

			_destroyed = false;
			destroy.connect(() =>
			{
			    _destroyed = true;
			});
		}

		[GtkCallback]
		private bool search_key_entry_pressed(Gdk.EventKey event_key)
		{
			if (event_key.keyval == Gdk.Key.Return)
			{
				if (shadertoy_search_entry.text != "")
				{
					search(shadertoy_search_entry.text);
				}
			}

			return false;
		}

		[GtkCallback]
		private void selected_children_changed()
		{
			if (shader_box.get_selected_children().length() == 1)
			{
				ShadertoyShaderItem selected_shadertoy_item = shader_box.get_selected_children().nth_data(0) as ShadertoyShaderItem;
				selected_shader = selected_shadertoy_item.shader;

				load_shader_button.sensitive = true;
			}
		}

		private void show_n_more_shaders(int n)
		{
		    if (n == 0)
		    {
		        return;
		    }

		    if (_found_shaders != null && _last_index < _found_shaders.length)
			{
			    int loc_index = _last_index;
				_last_index++;

				if (_found_shaders[_last_index] != null)
				{
					ShadertoyShaderItem element = new ShadertoyShaderItem();
					shader_box.add(element);

			        element.sh_it_name = _found_shaders[loc_index].shader_name;
			        element.author = _found_shaders[loc_index].author;
			        element.likes = (int) _found_shaders[loc_index].likes;
			        element.views = (int) _found_shaders[loc_index].views;
			        element.shader = _found_shaders[loc_index];

			        element._shadertoy_area.compilation_finished.connect(() =>
			        {
			            show_n_more_shaders(n - 1);
			        });

			        try
			        {
			            print(@"Compiling $(element.sh_it_name)\n");
				        element.compile();
			        }
			        catch (ShaderError e)
			        {
				        print(@"Compilation error: $(e.message)");
			        }
				}
			}
		}

		[GtkCallback]
		private void visible_child_changed()
		{
			if (content_stack.visible_child_name == "content" &&
			    content_stack.visible_child_name != _current_child)
			{
				_last_index = 0;

				show_n_more_shaders(16);

				/*for (int i = 0; i < 4; i++)
				{
					show_n_more_shaders(4);

					Gtk.Allocation allocation;
					shader_box.get_allocated_size(out allocation, null);

					if (allocation.y > 20)
					{
						break;
					}
				}*/

				/*Gtk.Allocation allocation;
				shader_box.get_allocation(out allocation);
				while (allocation.y < 100 && _last_index < _found_shaders.length);
				{
					show_n_more_shaders(4);

					Thread.usleep(500000);

					shader_box.get_allocation(out allocation);
				}*/
			}

			// for some reason the corresponding signal is emitted twice, so
			// we have to remember the state
			_current_child = content_stack.visible_child_name;
		}

		[GtkCallback]
		private void edge_reached(Gtk.PositionType position_type)
		{
			/*if (position_type == Gtk.PositionType.BOTTOM)
			{
				if (_last_index < _found_shaders.length)
				{
					show_n_more_shaders(4);
				}
			}*/
		}

		public void search(string search_string)
		{
			shader_box.forall((widget) =>
			{
				shader_box.remove(widget);
			});

			loading_label.set_text("Loading shaders...");
			content_stack.visible_child_name = "spinner";
			shadertoy_search_entry.sensitive = false;

			ShadertoySearch shadertoy_search = new ShadertoySearch();

			shadertoy_search.download_proceeded.connect((count, num_shaders) =>
			{
			    loading_label.set_text(@"Loaded $count/$num_shaders shaders...");
			});

			shadertoy_search.search.begin(search_string, (object, resource) =>
			{
			    _found_shaders = shadertoy_search.search.end(resource);

			    content_stack.visible_child_name = "content";
                shadertoy_search_entry.sensitive = true;
			});
		}
	}
}
