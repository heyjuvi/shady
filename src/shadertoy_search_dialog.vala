namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shadertoy-search-dialog.ui")]
	public class ShadertoySearchDialog : Gtk.Dialog
	{
		private static string API_KEY = "BtnKW8";

		public Shader selected_shader { get; private set; default = null; }

		[GtkChild]
		private Gtk.SearchEntry shadertoy_search_entry;

		[GtkChild]
		private Gtk.Button load_shader_button;

		[GtkChild]
		private Gtk.FlowBox shader_box;

		construct
		{
			// it is not so super clear, why this cannot be set in the ui file
			this.use_header_bar = 1;
		}

		public ShadertoySearchDialog(Gtk.Window parent)
		{
			set_transient_for(parent);
		}

		[GtkCallback]
		private bool search_key_entry_pressed(Gdk.EventKey event_key)
		{
			if (event_key.keyval == Gdk.Key.Return)
			{
				search(shadertoy_search_entry.text);
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

				load_shader_button.set_sensitive(true);
			}
		}

		public void search(string search_string)
		{
			new Thread<int>.try("search_thread", () =>
			{
				search_shaders(search_string);

				return 0;
			});
		}

		private void search_shaders(string search_string)
		{
			var search_session = new Soup.Session();

			string search_uri = @"https://www.shadertoy.com/api/v1/shaders/query/$search_string?key=$API_KEY";
			var search_message = new Soup.Message("GET", search_uri);

			search_session.send_message(search_message);

			try
			{
				var search_parser = new Json.Parser();
				search_parser.load_from_data((string) search_message.response_body.flatten().data, -1);

				var search_root = search_parser.get_root().get_object();
				var results = search_root.get_array_member("Results");

				foreach (var result_node in results.get_elements())
				{
					var shader_session = new Soup.Session();

					string shader_uri = @"https://www.shadertoy.com/api/v1/shaders/$(result_node.get_string())?key=$API_KEY";

					new Thread<int>.try("shader_thread", () =>
					{
						var shader_message = new Soup.Message("GET", shader_uri);

						shader_session.send_message(shader_message);

						try
						{
							Shader shader = new Shader();

							var shader_parser = new Json.Parser();
							shader_parser.load_from_data((string) shader_message.response_body.flatten().data, -1);

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

								string buffer_type = renderpass_object.get_string_member("type");
								string buffer_name = renderpass_object.get_string_member("name");

								if (buffer_type == "image" || buffer_type == "buffer")
								{
									if (buffer_name == "")
									{
										if (buffer_type == "image")
										{
											buffer_name = "Image";
										}
										else if (buffer_type == "buffer")
										{
											buffer_name = @"Buf $((char) (0x41 + buffer_counter))'";
											buffer_counter++;
										}
									}

									shader.buffers.insert(buffer_name, new Shader.Buffer());

									shader.buffers[buffer_name].type = buffer_type;
									shader.buffers[buffer_name].name = buffer_name;

									shader.buffers[buffer_name].code = renderpass_object.get_string_member("code");
									shader.buffers[buffer_name].code = shader.buffers[buffer_name].code.replace("\\n", "\n");
									shader.buffers[buffer_name].code = shader.buffers[buffer_name].code.replace("\\t", "\t");
								}
							}

							Idle.add(() =>
							{
								ShadertoyShaderItem element = new ShadertoyShaderItem();
								shader_box.add(element);

								element.name = shader.name;
								element.author = shader.author;
								element.likes = (int) shader.likes;
								element.views = (int) shader.views;
								element.shader = shader;

								Idle.add(() =>
								{
									try
									{
										element.compile();
									}
									catch (ShaderError e)
									{
										print(@"Compilation error: $(e.message)");
									}

									return false;
								}, Priority.HIGH);

								return false;
							}, Priority.DEFAULT_IDLE);

							Thread.usleep(500000);
						}
						catch (Error e)
						{
							stderr.printf("I guess something is not working...\n");
						}

						return 0;
					});
				}
			}
			catch (Error e)
			{
				stderr.printf("I guess something is not working...\n");
			}
		}
	}
}
