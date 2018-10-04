namespace Shady.Core
{
	public class SourceGenerator
	{
		private const string _channel_string = "iChannel";

		private const string _line_directive = "#line 1\n";

		public SourceGenerator()
		{
		}

		public static HashTable<string, string> generate_shader_source(Shader shader)
		{
			HashTable<string, string> string_table = new HashTable<string, string>(str_hash, str_equal);
			for(int i=0;i<shader.renderpasses.length;i++)
			{
				Shader.Renderpass renderpass = shader.renderpasses.index(i);
				string_table.insert(renderpass.name, generate_renderpass_source(renderpass));
			}

			return string_table;
		}

		public static string generate_renderpass_source(Shader.Renderpass renderpass)
		{
			try
			{
				string shader_prefix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/prefix.glsl", 0).get_data());
				string shader_builtins = (string) (resources_lookup_data("/org/hasi/shady/data/shader/builtin_function_backport.glsl", 0).get_data());
				string shader_suffix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/suffix.glsl", 0).get_data());

				string channel_prefix = "";

				for(int i=0;i<renderpass.inputs.length;i++)
				{
					int index = renderpass.inputs.index(i).channel;
					if(renderpass.inputs.index(i).type == Shader.InputType.TEXTURE ||
					   renderpass.inputs.index(i).type == Shader.InputType.BUFFER ||
					   renderpass.inputs.index(i).type == Shader.InputType.KEYBOARD ||
					   renderpass.inputs.index(i).type == Shader.InputType.WEBCAM ||
					   renderpass.inputs.index(i).type == Shader.InputType.MICROPHONE ||
					   renderpass.inputs.index(i).type == Shader.InputType.SOUNDCLOUD ||
					   renderpass.inputs.index(i).type == Shader.InputType.VIDEO ||
					   renderpass.inputs.index(i).type == Shader.InputType.MUSIC)
					{
						channel_prefix += "uniform lowp sampler2D " + _channel_string + @"$index;\n";
					}
					else if(renderpass.inputs.index(i).type == Shader.InputType.3DTEXTURE)
					{
						channel_prefix += "uniform lowp sampler3D " + _channel_string + @"$index;\n";
					}
					else if(renderpass.inputs.index(i).type == Shader.InputType.CUBEMAP)
					{
						channel_prefix += "uniform lowp samplerCube " + _channel_string + @"$index;\n";
					}
				}

				return App.app_preferences.glsl_version.to_prefix_string() +
				       shader_prefix +
				       shader_builtins +
				       channel_prefix +
				       _line_directive +
				       renderpass.code +
				       shader_suffix;
			}
			catch (Error e)
			{
				print("Couldn't load shader prefix or suffix\n");
				return "";
			}
		}

		public static string generate_vertex_source()
		{
			try
			{
				string vertex_source = (string) (resources_lookup_data("/org/hasi/shady/data/shader/vertex.glsl", 0).get_data());
				return App.app_preferences.glsl_version.to_prefix_string() + vertex_source;
			}
			catch(Error e)
			{
				print("Couldn't load vertex shader\n");
				return "";
			}
			
		}
	}
}
