namespace Shady
{
	public class ShadertoyResourceManager : Object
	{
		private static string TEXTURE_PREFIX = "/org/hasi/shady/data/shadertoy_presets/textures";

		public static string[] TEXTURE_IDS =
		{
			"abstract_1",
			"abstract_2",
			"abstract_3",
			"bayer",
			"font_1",
			"gray_noise_medium",
			"gray_noise_small",
			"lichen",
			"london",
			"nyancat",
			"organic_1",
			"organic_2",
			"organic_3",
			"organic_4",
			"pebbles",
			"rgba_noise_medium",
			"rgba_noise_small",
			"rock_tiles",
			"rusty_metal",
			"stars",
			"wood"
		};

		public static HashTable<string, Gdk.Pixbuf> TEXTURE_PIXBUFS = new HashTable<string, Gdk.Pixbuf>(str_hash, str_equal);
		public static HashTable<string, Shader.Input> TEXTURES = new HashTable<string, Shader.Input>(str_hash, str_equal);

		construct
		{
			foreach (string texture_id in TEXTURE_IDS)
			{
				Shader.Input texture = load_texture(texture_id);

				TEXTURES.insert(texture_id, texture);
				TEXTURE_PIXBUFS.insert(texture.resource, new Gdk.Pixbuf.from_resource(texture.resource));
			}
		}

		public static Shader.Input? load_texture(string texture_id)
		{
			File texture_json_file = File.new_for_uri(@"resource://$(TEXTURE_PREFIX)/$(texture_id).json");

			try
			{
				var texture_parser = new Json.Parser();
				texture_parser.load_from_data(read_file_as_string(texture_json_file), -1);

				var texture_root = texture_parser.get_root().get_object();

				Shader.Input texture = new Shader.Input();
				texture.hash = texture_root.get_string_member("hash");
				texture.resource = texture_root.get_string_member("resource");
				texture.name = texture_root.get_string_member("name");

				return texture;
			}
			catch (Error e)
			{
				print(@"Could not load texture $texture_id: $(e.message)\n");

				return null;
			}
		}
	}
}
