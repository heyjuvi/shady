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
				foreach (var renderpass in renderpasses_node.get_elements())
				{
					var renderpass_object = renderpass.get_object();

					string renderpass_type = renderpass_object.get_string_member("type");
					string renderpass_name = renderpass_object.get_string_member("name");

					Shader.Renderpass new_renderpass = new Shader.Renderpass();
					new_renderpass.type = Shader.RenderpassType.from_string(renderpass_type);

					if (new_renderpass.type == Shader.RenderpassType.SOUND)
					{
						renderpass_name = "Sound";
					}
					else if (new_renderpass.type == Shader.RenderpassType.IMAGE)
					{
						renderpass_name = "Image";
					}
					else if (new_renderpass.type == Shader.RenderpassType.COMMON)
					{
						renderpass_name = "Common";
					}
					else if (new_renderpass.type == Shader.RenderpassType.BUFFER)
					{
						// Normalize the buffer name to our scheme
						renderpass_name = renderpass_name.replace("Buffer", "Buf");
					}

					new_renderpass.name = renderpass_name;
					new_renderpass.code = renderpass_object.get_string_member("code");

					print(@"--- $renderpass_name, $renderpass_type ---\n");

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

						// We normalize the id's to our own scheme, so there is ambiguity
						shader_output.id = (int) output_object.get_int_member("id");

						shader_output.channel = (int) output_object.get_int_member("channel");

						new_renderpass.outputs.append_val(shader_output);
					}

					shader.renderpasses.append_val(new_renderpass);
				}

				// Walk through all renderpasses and normalize input/output id relations to our
				// scheme, so there will not be any ambiguity
				for (int i = 0; i < shader.renderpasses.length; i++)
				{
					var renderpass = shader.renderpasses.index(i);
					for (int j = 0; j < renderpass.outputs.length; j++)
					{
						int output_id = renderpass.outputs.index(j).id;
						for (int k = 0; k < shader.renderpasses.length; k++)
						{
							var match_renderpass = shader.renderpasses.index(k);
							for (int l = 0; l < match_renderpass.inputs.length; l++)
							{
								int input_id = match_renderpass.inputs.index(l).id;
								if (input_id == output_id)
								{
									int normalized_id = Shader.RENDERPASSES_ORDER[renderpass.name];
									renderpass.outputs.index(j).id = normalized_id;
									match_renderpass.inputs.index(l).id = normalized_id;
								}
							}
						}
					}
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

	public class ShadertoySearch
	{
	    public signal void download_proceeded(int count, int num_shaders);

        private static string API_KEY = "BtnKW8";

	    private Shader?[] _found_shaders;
	    private bool _canceled;

	    private static ThreadPool<LoadShaderThread> _search_pool;

	    static construct
	    {
	        try
			{
				_search_pool = new ThreadPool<LoadShaderThread>.with_owned_data((load_shader_thread) =>
				{
					load_shader_thread.run();
				}, (int) GLib.get_num_processors() * 4, false);
			}
			catch (Error e)
			{
				print("Could not initialize ThreadPool for Shadertoy search!\n");
			}
	    }

	    public ShadertoySearch()
	    {
	        _found_shaders = null;
	        _canceled = false;
	    }

	    public void cancel()
	    {
	        _canceled = true;
	    }

	    public async Shader?[] search(string search_string)
		{
		    SourceFunc callback = search.callback;

			ThreadFunc<bool> run = () =>
			{
				int num_shaders = (int) search_shaders(search_string);

				bool search_finished = false;
				while (!search_finished && !_canceled)
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

					Idle.add(() =>
					{
					    download_proceeded(count, num_shaders);
					    return false;
					});

					Thread.usleep(1000000);
				}

				Idle.add((owned) callback);

				return true;
			};
			new Thread<bool>("search_thread", run);

			yield;

			return _found_shaders;
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
					//new Thread<int>("shader_thread", load_thread.run);
					_search_pool.add(load_thread);

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
