namespace Shady
{
	[GtkTemplate (ui = "/org/hasi/shady/ui/shadertoy-search-dialog.ui")]
	public class ShadertoySearchDialog : Gtk.Dialog
	{
		private static string API_KEY = "BtnKW8";

		public string selected_shader { get; private set; default = ""; }

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
			var session = new Soup.Session();

			string search_uri = @"https://www.shadertoy.com/api/v1/shaders/query/$search_string?key=$API_KEY";
			var search_message = new Soup.Message("GET", search_uri);

			session.send_message(search_message);

			try
			{
				var search_parser = new Json.Parser();
				search_parser.load_from_data((string) search_message.response_body.flatten().data, -1);

				var search_root = search_parser.get_root().get_object();
				var results = search_root.get_array_member("Results");

				foreach (var result_node in results.get_elements())
				{
					string shader_uri = @"https://www.shadertoy.com/api/v1/shaders/$(result_node.get_string())?key=$API_KEY";

					new Thread<int>.try("shader_thread", () =>
					{
						var shader_message = new Soup.Message("GET", shader_uri);

						session.send_message(shader_message);

						try
						{
							var shader_parser = new Json.Parser();
							shader_parser.load_from_data((string) shader_message.response_body.flatten().data, -1);

							var shader_root = shader_parser.get_root().get_object().get_object_member("Shader");
							var info_node = shader_root.get_object_member("info");

							string name = info_node.get_string_member("name");
							string author = info_node.get_string_member("username");
							int64 likes = info_node.get_int_member("likes");
							int64 views = info_node.get_int_member("viewed");

							var renderpasses_node = shader_root.get_array_member("renderpass");

							foreach (var renderpass in renderpasses_node.get_elements())
							{
								var renderpass_object = renderpass.get_object();
								string type = renderpass_object.get_string_member("type");

								if (type == "image")
								{
									string code = renderpass_object.get_string_member("code");
									code = code.replace("\\n", "\n");
									code = code.replace("\\t", "\t");

									Idle.add(() =>
									{
										ShadertoyShaderItem element = new ShadertoyShaderItem();
										shader_box.add(element);

										element.name = name;
										element.author = author;
										element.likes = (int) likes;
										element.views = (int) views;
										element.shader = code;

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
							}
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
