namespace Shady
{
    public class LoadShaderThread
	{
		public signal void loading_finished();

		public string shader_uri;
		public int shader_index;

		public Shader? shader = null;
		public bool invalid_result = false;

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

				invalid_result = false;

				var shader_parser = new Json.Parser();

				string shader_data = (string) shader_message.response_body.flatten().data;
				//shader_data = shader_data[3:shader_data.length];

				shader_data = shader_data.replace("\\n", "\n");
				shader_data = shader_data.replace("\\t", "\t");
				shader_data = shader_data.replace("\\/", "/");

				shader_parser.load_from_data(shader_data, -1);

				if (shader_parser.get_root() == null)
				{
				    invalid_result = true;
				    shader = null;
				    loading_finished();

				    return -1;
				}

				if (shader_parser.get_root().get_object().has_member("Error"))
				{
				    invalid_result = true;
				    shader = null;
				    loading_finished();

				    return -1;
				}

				var shader_root = shader_parser.get_root().get_object().get_object_member("Shader");
				var info_node = shader_root.get_object_member("info");

				shader.shader_name = info_node.get_string_member("name");
				shader.description = info_node.get_string_member("description");
				shader.author = info_node.get_string_member("username");
				shader.likes = (int) info_node.get_int_member("likes");
				shader.views = (int) info_node.get_int_member("viewed");
				shader.date = new DateTime.from_unix_utc(int64.parse(info_node.get_string_member("date")));

				var tags_node = info_node.get_array_member("tags");
				int tag_counter = 0;
				shader.tags = new string[tags_node.get_elements().length()];
				foreach (var tag in tags_node.get_elements())
				{
				    shader.tags[tag_counter] = tag.get_string();
				    tag_counter++;
				}

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

					new_renderpass.renderpass_name = renderpass_name;
					new_renderpass.code = renderpass_object.get_string_member("code");

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
						if (shader_input.type == Shader.InputType.TEXTURE)
						{
						    string hash = ShadertoyResourceManager.src_to_hash(input_object.get_string_member("src"));
						    var texture_input = ShadertoyResourceManager.get_texture_by_hash(hash);

						    if (texture_input != null)
						    {
						        shader_input.assign_content(texture_input);
						    }
						}
						else if (shader_input.type == Shader.InputType.3DTEXTURE)
						{
						    string hash = ShadertoyResourceManager.src_to_hash(input_object.get_string_member("src"));
						    var 3dtexture_input = ShadertoyResourceManager.get_3dtexture_by_hash(hash);

						    if (3dtexture_input != null)
						    {
						        shader_input.assign_content(3dtexture_input);
						    }
						}
						else if (shader_input.type == Shader.InputType.CUBEMAP)
						{
						    string hash = ShadertoyResourceManager.src_to_hash(input_object.get_string_member("src"));
						    var cubemap_input = ShadertoyResourceManager.get_cubemap_by_hash(hash);

						    if (cubemap_input != null)
						    {
						        shader_input.assign_content(cubemap_input);
						    }
						}
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
									int normalized_id = Shader.RENDERPASSES_ORDER[renderpass.renderpass_name];
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

        public static const string API_KEY = "BtnKW8";

	    private Shader?[] _found_shaders;
	    private bool[] _valid;
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
		    SourceFunc search_callback = this.search.callback;

            string? id = null;
		    if (search_string.has_prefix("http"))
		    {
		        id = search_string.split("shadertoy.com/view/")[1];
		    }
		    else if (search_string.has_prefix("id:"))
		    {
		        id = search_string.split("id:")[1];
		    }

		    ThreadFunc<bool> run = () =>
		    {
			    int num_shaders = -1;

			    if (id != null)
			    {
			        num_shaders = 1;
			        search_by_id(id);
			    }
			    else
			    {
			        num_shaders = (int) search_shaders(search_string);
			    }

			    bool search_finished = false;
			    while (!search_finished && !_canceled)
			    {
				    int count = 0;
				    bool null_shader_found = false;
				    for (int i = 0; i < num_shaders; i++)
				    {
					    if (_found_shaders[i] == null && _valid[i])
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

				    Timeout.add(0, () =>
				    {
				        download_proceeded(count, num_shaders);
				        return false;
				    });

                    if (!search_finished)
                    {
				        Thread.usleep(10000);
				    }
			    }

                // TODO: why is the timeout necessary and Idle.add does not work?
                // is it a race condition?
			    Timeout.add(0, () =>
			    {
			        search_callback();
			        return false;
			    });

			    return true;
		    };
		    new Thread<bool>("search_thread", (owned) run);

			yield;

			Array<Shader> valid_shaders = new Array<Shader>();
			foreach (Shader shader in _found_shaders)
			{
			    if (shader != null)
			    {
			        valid_shaders.append_val(shader);
			    }
			}

			return valid_shaders.data;
		}

		public string[]? search_shader_ids(string search_string)
		{
		    var search_session = new Soup.Session();

			string search_uri = @"https://www.shadertoy.com/api/v1/shaders/query/$search_string?key=$API_KEY";
			var search_message = new Soup.Message("GET", search_uri);

			search_session.send_message(search_message);

			uint64 num_shaders = 0;

			try
			{
				var search_parser = new Json.Parser();
				string json_data = (string) search_message.response_body.flatten().data;
				//json_data = json_data[3:json_data.length];
				search_parser.load_from_data(json_data, -1);

				var search_root = search_parser.get_root().get_object();

				num_shaders = search_root.get_int_member("Shaders");
				if (num_shaders == 0)
				{
                    return {};
				}

				var results = search_root.get_array_member("Results");
				Array<string> result_ids = new Array<string>();
				foreach (var result_node in results.get_elements())
				{
				    result_ids.append_val(result_node.get_string());
				}

				return result_ids.data;
			}
			catch (Error e)
			{
				stderr.printf(@"I guess something is not working... $(e.message)\n");
			}

			return null;
		}

		private void search_by_id(string id)
		{
		    string shader_uri = @"https://www.shadertoy.com/api/v1/shaders/$id?key=$API_KEY";

		    _found_shaders = new Shader[1];
		    _valid = new bool[1];

		    _found_shaders[0] = null;
		    _valid[0] = true;

			LoadShaderThread load_thread = new LoadShaderThread(shader_uri, 0);
			load_thread.loading_finished.connect(() =>
			{
			    debug(@"finished loading $(load_thread.shader_uri)");

			    _valid[0] = !load_thread.invalid_result;
				_found_shaders[load_thread.shader_index] = load_thread.shader;
			});
			new Thread<int>("shader_id_thread", load_thread.run);
		}

        // TODO: handle the invalid shaders
		private uint64 search_shaders(string search_string)
		{
            string[] result_ids = search_shader_ids(search_string);
			uint64 num_shaders = result_ids.length;

			try
			{
				_found_shaders = new Shader[num_shaders];
				_valid = new bool[num_shaders];

				for (int i = 0; i < num_shaders; i++)
				{
					_found_shaders[i] = null;
					_valid[i] = true;
				}

				int index = 0;
				foreach (var result_id in result_ids)
				{
					string shader_uri = @"https://www.shadertoy.com/api/v1/shaders/$(result_id)?key=$API_KEY";

                    debug(@"starting load thread for $shader_uri");

					LoadShaderThread load_thread = new LoadShaderThread(shader_uri, index);
					load_thread.loading_finished.connect(() =>
					{
					    debug(@"finished loading $(load_thread.shader_uri)");

                        _valid[0] = !load_thread.invalid_result;
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
				stderr.printf(@"I guess something is not working... $(e.message)\n");
			}

			return num_shaders;
		}
	}
}
