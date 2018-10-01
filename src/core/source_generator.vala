namespace Shady.Core
{
	public class SourceGenerator
	{
		private const string _channel_string = "iChannel";
		private const string _version_prefix = "#version 300 es\n\n";

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

		public static uint renderpass_prefix_line_count(Shader.Renderpass renderpass)
		{
			try
			{
				string shader_prefix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/prefix.glsl", 0).get_data());

				uint input_count = 0;

				for(int i=0;i<renderpass.inputs.length;i++)
				{
					Shader.Input input = renderpass.inputs.index(i);
					if(input.type != Shader.InputType.NONE && input.type != Shader.InputType.INVALID)
					{
						input_count++;
					}
				}

				return shader_prefix.split("\n").length + input_count + _version_prefix.split("\n").length;
			}
			catch (Error e)
			{
				print("Couldn't load shader prefix or suffix\n");
				return 0;
			}
		}

		public static string generate_renderpass_source(Shader.Renderpass renderpass)
		{
			try
			{
				string shader_prefix = (string) (resources_lookup_data("/org/hasi/shady/data/shader/prefix.glsl", 0).get_data());
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
						channel_prefix += "uniform sampler2D " + _channel_string + @"$index;\n";
					}
					else if(renderpass.inputs.index(i).type == Shader.InputType.3DTEXTURE)
					{
						channel_prefix += "uniform sampler3D " + _channel_string + @"$index;\n";
					}
					else if(renderpass.inputs.index(i).type == Shader.InputType.CUBEMAP)
					{
						channel_prefix += "uniform samplerCube " + _channel_string + @"$index;\n";
					}
				}

				return _version_prefix + shader_prefix + channel_prefix + renderpass.code + shader_suffix;
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
				return _version_prefix + vertex_source;
			}
			catch(Error e)
			{
				print("Couldn't load vertex shader\n");
				return "";
			}
			
		}
	}
}
