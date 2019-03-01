namespace Shady
{
	public class ShadertoyResourceManager : Object
	{
		private static string TEXTURE_PREFIX = "/org/hasi/shady/data/shadertoy_presets/textures";
		private static string 3DTEXTURE_PREFIX = "/org/hasi/shady/data/shadertoy_presets/3dtextures";
		private static string CUBEMAP_PREFIX = "/org/hasi/shady/data/shadertoy_presets/cubemaps";

		public static string[] TEXTURE_IDS =
		{
			"abstract_1",
			"abstract_2",
			"abstract_3",
			"bayer",
			"blue_noise",
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
			"wood",
			"buffer00",
			"buffer01",
			"buffer02",
			"buffer03"
		};

		public static string[] 3DTEXTURE_IDS =
		{
			"gray_noise3d",
			"rgba_noise3d"
		};

		public static string[] CUBEMAP_IDS =
		{
			"forest",
			"forest_blurred",
			"st_peters",
			"st_peters_blurred",
			"uffizi_gallery",
			"uffizi_gallery_blurred"
		};

		public class Voxmap
		{
			public int width;
			public int height;
			public int depth;
			public int n_channels;
			public uint8[] voxels;
		}

		public static Gdk.Pixbuf[] TEXTURE_PIXBUFS;
		public static Shader.Input[] TEXTURES;

		public static Voxmap[] 3DTEXTURE_VOXMAPS;
		public static Shader.Input[] 3DTEXTURES;

		public static Gdk.Pixbuf[,] CUBEMAP_PIXBUFS_ARRAY;
		public static Shader.Input[] CUBEMAPS;

		construct
		{
			TEXTURE_PIXBUFS = new Gdk.Pixbuf[TEXTURE_IDS.length];
			TEXTURES = new Shader.Input[TEXTURE_IDS.length];

			for (int i = 0; i < TEXTURE_IDS.length; i++)
			{
				Shader.Input? texture = load_texture(TEXTURE_IDS[i]);
				texture.resource_index = i;
				TEXTURES[i] = texture;

				try
				{
					TEXTURE_PIXBUFS[i] = new Gdk.Pixbuf.from_resource(texture.resource);
				}
				catch (Error e)
				{
					print(@"Couldn't load texture: $(e.message)\n");
				}
			}

			3DTEXTURE_VOXMAPS = new Voxmap[3DTEXTURE_IDS.length];
			3DTEXTURES = new Shader.Input[3DTEXTURE_IDS.length];

			for (int i = 0; i < 3DTEXTURE_IDS.length; i++)
			{
				string _3dtexture_id = 3DTEXTURE_IDS[i];
				Shader.Input? 3dtexture = load_3dtexture(3DTEXTURE_IDS[i]);
				3dtexture.resource_index = i;
				3DTEXTURES[i] = 3dtexture;

				try
				{
					3DTEXTURE_VOXMAPS[i] = new Voxmap();
					uint8[] data = resources_lookup_data(3dtexture.resource, 0).get_data();

					3DTEXTURE_VOXMAPS[i].width = bytes_to_int(data[4:8]);
					3DTEXTURE_VOXMAPS[i].height = bytes_to_int(data[8:12]);
					3DTEXTURE_VOXMAPS[i].depth = bytes_to_int(data[12:16]);
					3DTEXTURE_VOXMAPS[i].n_channels = bytes_to_int(data[16:20]);
					3DTEXTURE_VOXMAPS[i].voxels = data[20:data.length];
				}
				catch (Error e)
				{
					print(@"Couldn't load 3dtexture: $(e.message)\n");
				}
			}

			CUBEMAP_PIXBUFS_ARRAY = new Gdk.Pixbuf[CUBEMAP_IDS.length, 6];
			CUBEMAPS = new Shader.Input[CUBEMAP_IDS.length];

			for (int i = 0; i < CUBEMAP_IDS.length; i++)
			{
				Shader.Input? cubemap = load_cubemap(CUBEMAP_IDS[i]);
				cubemap.resource_index = i;
				CUBEMAPS[i] = cubemap;

				try
				{
					for (int j = 0; j < 6; j++)
					{
						CUBEMAP_PIXBUFS_ARRAY[i, j] = new Gdk.Pixbuf.from_resource(cubemap.resource.replace("$j", @"$j"));
					}
				}
				catch (Error e)
				{
					print(@"Couldn't load cubemap: $(e.message)\n");
				}
			}
		}

		private static int bytes_to_int(uint8[] bytes)
		{
			return bytes[3] << 24 | bytes[2] << 16 | bytes[1] << 8 | bytes[0];
		}

		public int texture_index_from_string(string index)
		{
			int i;
			for (i = 0; i < TEXTURE_IDS.length; i++)
			{
				if (TEXTURE_IDS[i] == index)
				{
					break;
				}
			}

			if (i == TEXTURE_IDS.length)
			{
				print("Texture index not found");
			}

			return i;
		}

		public int 3dtexture_index_from_string(string index)
		{
			int i;
			for (i = 0; i < 3DTEXTURE_IDS.length; i++)
			{
				if(3DTEXTURE_IDS[i] == index)
				{
					break;
				}
			}

			if (i == 3DTEXTURE_IDS.length)
			{
				print("3dtexture index not found");
			}

			return i;
		}

		public int cubemap_index_from_string(string index)
		{
			int i;
			for (i = 0; i < CUBEMAP_IDS.length; i++)
			{
				if(CUBEMAP_IDS[i] == index)
				{
					break;
				}
			}

			if (i == CUBEMAP_IDS.length)
			{
				print("Cubemap index not found");
			}

			return i;
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
				texture.type = Shader.InputType.TEXTURE;
				texture.hash = texture_root.get_string_member("hash");
				texture.resource = texture_root.get_string_member("resource");
				texture.n_channels = (int) texture_root.get_int_member("channels");
				texture.name = texture_root.get_string_member("name");

				return texture;
			}
			catch (Error e)
			{
				print(@"Could not load texture $texture_id: $(e.message)\n");

				return null;
			}
		}

		public static Shader.Input? get_texture_by_name(string name)
		{
		    foreach (var texture in TEXTURES)
		    {
		        if (texture.name == name)
		        {
		            return texture;
		        }
		    }

		    return null;
		}

		public static Shader.Input? load_3dtexture(string _3dtexture_id)
		{
			File 3dtexture_json_file = File.new_for_uri(@"resource://$(3DTEXTURE_PREFIX)/$(_3dtexture_id).json");

			try
			{
				var 3dtexture_parser = new Json.Parser();
				3dtexture_parser.load_from_data(read_file_as_string(3dtexture_json_file), -1);

				var 3dtexture_root = 3dtexture_parser.get_root().get_object();

				Shader.Input 3dtexture = new Shader.Input();
				3dtexture.type = Shader.InputType.3DTEXTURE;
				3dtexture.hash = 3dtexture_root.get_string_member("hash");
				3dtexture.resource = 3dtexture_root.get_string_member("resource");
				3dtexture.n_channels = (int) 3dtexture_root.get_int_member("channels");
				3dtexture.name = 3dtexture_root.get_string_member("name");

				return 3dtexture;
			}
			catch (Error e)
			{
				print(@"Could not load 3dtexture $(_3dtexture_id): $(e.message)\n");

				return null;
			}
		}

		public static Shader.Input? get_3dtexture_by_name(string name)
		{
		    foreach (var 3dtexture in 3DTEXTURES)
		    {
		        if (3dtexture.name == name)
		        {
		            return 3dtexture;
		        }
		    }

		    return null;
		}

		public static Shader.Input? load_cubemap(string cubemap_id)
		{
			File cubemap_json_file = File.new_for_uri(@"resource://$(CUBEMAP_PREFIX)/$(cubemap_id).json");

			try
			{
				var cubemap_parser = new Json.Parser();
				cubemap_parser.load_from_data(read_file_as_string(cubemap_json_file), -1);

				var cubemap_root = cubemap_parser.get_root().get_object();

				Shader.Input cubemap = new Shader.Input();
				cubemap.type = Shader.InputType.CUBEMAP;
				cubemap.hash = cubemap_root.get_string_member("hash");
				cubemap.resource = cubemap_root.get_string_member("resource");
				cubemap.n_channels = (int) cubemap_root.get_int_member("channels");
				cubemap.name = cubemap_root.get_string_member("name");

				return cubemap;
			}
			catch (Error e)
			{
				print(@"Could not load cubemap $cubemap_id: $(e.message)\n");

				return null;
			}
		}

		public static Shader.Input? get_cubemap_by_name(string name)
		{
		    foreach (var cubemap in CUBEMAPS)
		    {
		        if (cubemap.name == name)
		        {
		            return cubemap;
		        }
		    }

		    return null;
		}
	}
}
