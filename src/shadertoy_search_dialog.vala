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

								string renderpass_type = renderpass_object.get_string_member("type");
								string renderpass_name = renderpass_object.get_string_member("name");

								Shader.Renderpass new_renderpass = new Shader.Renderpass();
								new_renderpass.type = Shader.RenderpassType.from_string(renderpass_type);
								new_renderpass.name = renderpass_name;

								if (new_renderpass.type == Shader.RenderpassType.AUDIO)
								{
									renderpass_name = "Audio";
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
								new_renderpass.code = new_renderpass.code.replace("\\n", "\n");
								new_renderpass.code = new_renderpass.code.replace("\\t", "\t");

								var inputs_node = renderpass_object.get_array_member("inputs");
								foreach (var input in inputs_node.get_elements())
								{
									var input_object = input.get_object();

									Shader.Input shader_input = new Shader.Input();
									shader_input.id = (int) input_object.get_int_member("id");
									shader_input.channel = (int) input_object.get_int_member("channel");
									shader_input.type = Shader.InputType.from_string(input_object.get_string_member("ctype"));

									new_renderpass.input_ids.append_val(shader_input.id);

									var input_sampler_object = input_object.get_object_member("sampler");

									Shader.Sampler shader_input_sampler = new Shader.Sampler();
									shader_input_sampler.filter = Shader.FilterMode.from_string(input_sampler_object.get_string_member("filter"));
									shader_input_sampler.wrap = Shader.WrapMode.from_string(input_sampler_object.get_string_member("wrap"));
									shader_input_sampler.v_flip = input_sampler_object.get_boolean_member("vflip");

									new_renderpass.samplers.insert(shader_input.id, shader_input_sampler);

									// if this is a known resource, add info to it from the resources
								}

								shader.renderpasses.append_val(new_renderpass);
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
