namespace Shady
{
	public class LoadShaderThread
	{
		public signal void loading_finished();

		public string shader_uri;
		public int shader_index;

		public Shader shader;

		public LoadShaderThread(string uri, int index)
		{
			shader_uri = uri;
			shader_index = index;
		}

		public int run()
		{
			var shader_session = new Soup.Session();
			var shader_message = new Soup.Message("GET", shader_uri);

			shader_session.send_message(shader_message);

			try
			{
				shader = new Shader();

				var shader_parser = new Json.Parser();

				string shader_data = (string) shader_message.response_body.flatten().data;
				shader_data = shader_data.replace("\\n", "\n");
				shader_data = shader_data.replace("\\t", "\t");
				shader_data = shader_data.replace("\\/", "/");

				shader_parser.load_from_data(shader_data, -1);

				var shader_root = shader_parser.get_root().get_object().get_object_member("Shader");
				var info_node = shader_root.get_object_member("info");

				shader.name = info_node.get_string_member("name");
				shader.author = info_node.get_string_member("username");
				shader.likes = (int) info_node.get_int_member("likes");
				shader.views = (int) info_node.get_int_member("viewed");

				var renderpasses_node = shader_root.get_array_member("renderpass");

				int buffer_counter = 0;
				foreach (var renderpass in renderpasses_node.get_elements())
				{
					var renderpass_object = renderpass.get_object();

					string renderpass_type = renderpass_object.get_string_member("type");
					string renderpass_name = renderpass_object.get_string_member("name");

					Shader.Renderpass new_renderpass = new Shader.Renderpass();
					new_renderpass.type = Shader.RenderpassType.from_string(renderpass_type);
					new_renderpass.name = renderpass_name;

					if (new_renderpass.type == Shader.RenderpassType.SOUND)
					{
						renderpass_name = "Sound";
					}
					else if (new_renderpass.type == Shader.RenderpassType.IMAGE)
					{
						renderpass_name = "Image";
					}
					else if (new_renderpass.type == Shader.RenderpassType.BUFFER)
					{
						renderpass_name = @"Buf $((char) (0x41 + buffer_counter))'";
						buffer_counter++;
					}

					new_renderpass.code = renderpass_object.get_string_member("code");
					//new_renderpass.code = new_renderpass.code.replace("\\n", "\n");
					//new_renderpass.code = new_renderpass.code.replace("\\t", "\t");

					var inputs_node = renderpass_object.get_array_member("inputs");
					foreach (var input in inputs_node.get_elements())
					{
						var input_object = input.get_object();

						Shader.Input shader_input = new Shader.Input();
						shader_input.id = (int) input_object.get_int_member("id");
						shader_input.channel = (int) input_object.get_int_member("channel");
						shader_input.type = Shader.InputType.from_string(input_object.get_string_member("ctype"));

						var input_sampler_object = input_object.get_object_member("sampler");

						Shader.Sampler shader_input_sampler = new Shader.Sampler();
						shader_input_sampler.filter = Shader.FilterMode.from_string(input_sampler_object.get_string_member("filter"));
						shader_input_sampler.wrap = Shader.WrapMode.from_string(input_sampler_object.get_string_member("wrap"));
						shader_input_sampler.v_flip = input_sampler_object.get_boolean_member("vflip");

						shader_input.sampler = shader_input_sampler;

						new_renderpass.inputs.append_val(shader_input);

						// if this is a known resource, add info to it from the resources
					}

					var outputs_node = renderpass_object.get_array_member("outputs");
					foreach (var output in outputs_node.get_elements())
					{
						var output_object = output.get_object();

						Shader.Output shader_output = new Shader.Output();
						shader_output.id = (int) output_object.get_int_member("id");
						shader_output.channel = (int) output_object.get_int_member("channel");

						new_renderpass.outputs.append_val(shader_output);
					}

					shader.renderpasses.append_val(new_renderpass);
				}
			}
			catch (Error e)
			{
				stderr.printf("Could not load shader with id $shader_id\n");
			}

			loading_finished();

			return 0;
		}
	}

	[GtkTemplate (ui = "/org/hasi/shady/ui/shadertoy-search-dialog.ui")]
	public class ShadertoySearchDialog : Gtk.Dialog
	{
		private static string API_KEY = "BtnKW8";

		public Shader selected_shader { get; private set; default = null; }

		private Shader?[] _found_shaders = null;
		private int _last_index = 0;

		private string _current_child = "content";

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
		    print(@"YOLO: $_last_index, $(_found_shaders.length)\n");
			if (_found_shaders != null && _last_index < _found_shaders.length)
			{
				for (int i = 0; i < n && _last_index + i < _found_shaders.length; i++)
				{
					int shader_index = _last_index + i;

					if (_found_shaders[shader_index] != null)
					{
						ShadertoyShaderItem element = new ShadertoyShaderItem();
						shader_box.add(element);

						element.compile();
                        element._shader_manager.compilation_finished.connect(() =>
                        {
						    element.sh_it_name = _found_shaders[shader_index].name;
						    element.author = _found_shaders[shader_index].author;
						    element.likes = (int) _found_shaders[shader_index].likes;
						    element.views = (int) _found_shaders[shader_index].views;
						    element.shader = _found_shaders[shader_index];

						    try
						    {
							    element.compile();
						    }
						    catch (ShaderError e)
						    {
							    print(@"Compilation error: $(e.message)");
						    }
						});
					}
				}

				_last_index += n;
			}
		}

		[GtkCallback]
		private void visible_child_changed()
		{
			if (content_stack.visible_child_name == "content" &&
			    content_stack.visible_child_name != _current_child)
			{
				_last_index = 0;

				for (int i = 0; i < 4; i++)
				{
					show_n_more_shaders(4);

					Gtk.Allocation allocation;
					shader_box.get_allocated_size(out allocation, null);

					if (allocation.y > 20)
					{
						break;
					}
				}

				/*Gtk.Allocation allocation;
				shader_box.get_allocation(out allocation);
				print(@"$(allocation.y)\n");
				print("Geht das noch?\n");
				while (allocation.y < 100 && _last_index < _found_shaders.length);
				{
					print("Ja!\n");
					print(@"$(allocation.y)\n");

					show_n_more_shaders(4);

					Thread.usleep(500000);

					shader_box.get_allocation(out allocation);
				}

				print("??????????????????\n");*/
			}

			// for some reason the corresponding signal is emitted twice, so
			// we have to remember the state
			_current_child = content_stack.visible_child_name;
		}

		[GtkCallback]
		private void edge_reached(Gtk.PositionType position_type)
		{
			if (position_type == Gtk.PositionType.BOTTOM)
			{
				if (_last_index < _found_shaders.length)
				{
					show_n_more_shaders(4);
				}
			}
		}

		public void search(string search_string)
		{
			shader_box.forall((widget) =>
			{
				shader_box.remove(widget);
			});

			try
			{
				loading_label.set_text("Loading shaders...");
				content_stack.visible_child_name = "spinner";
				shadertoy_search_entry.sensitive = false;

				new Thread<int>.try("search_thread", () =>
				{
					uint64 num_shaders = search_shaders(search_string);

					bool search_finished = false;
					while (!search_finished && !_destroyed)
					{
						int count = 0;
						bool null_shader_found = false;
						for (int i = 0; i < num_shaders; i++)
						{
							if (_found_shaders[i] == null)
							{
								null_shader_found = true;
							}
							else
							{
								count++;
							}
						}

						if (!null_shader_found)
						{
							search_finished = true;
						}

                        if (!_destroyed)
                        {
						    Idle.add(() =>
						    {
							    loading_label.set_text(@"Loaded $count/$num_shaders shaders...");
							    return false;
						    });
						}

						Thread.usleep(1000000);
					}

					if (!_destroyed)
					{
					    Idle.add(() =>
					    {
						    content_stack.visible_child_name = "content";
						    shadertoy_search_entry.sensitive = true;
						    return false;
					    });
					}

					return 0;
				});
			}
			catch (Error e)
			{
				print("Couldn't start shader loading thread\n");
			}
		}

		private uint64 search_shaders(string search_string)
		{
			var search_session = new Soup.Session();

			string search_uri = @"https://www.shadertoy.com/api/v1/shaders/query/$search_string?key=$API_KEY";
			var search_message = new Soup.Message("GET", search_uri);

			search_session.send_message(search_message);

			uint64 num_shaders = 0;

			try
			{
				var search_parser = new Json.Parser();
				search_parser.load_from_data((string) search_message.response_body.flatten().data, -1);

				var search_root = search_parser.get_root().get_object();

				num_shaders = search_root.get_int_member("Shaders");
				var results = search_root.get_array_member("Results");

				_found_shaders = new Shader[num_shaders];

				for (int i = 0; i < num_shaders; i++)
				{
					_found_shaders[i] = null;
				}

				int index = 0;
				foreach (var result_node in results.get_elements())
				{
					string shader_uri = @"https://www.shadertoy.com/api/v1/shaders/$(result_node.get_string())?key=$API_KEY";

					LoadShaderThread load_thread = new LoadShaderThread(shader_uri, index);
					load_thread.loading_finished.connect(() =>
					{
						_found_shaders[load_thread.shader_index] = load_thread.shader;
					});

					//Thread thread = new Thread<int>("shader_thread", load_thread.run);
					new Thread<int>("shader_thread", load_thread.run);

					index++;
				}
			}
			catch (Error e)
			{
				stderr.printf("I guess something is not working...\n");
			}

			return num_shaders;
		}
	}
}
