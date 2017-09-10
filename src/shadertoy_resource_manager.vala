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
			public int channels;
			public uint8[] voxels;
		}

		public static Gdk.Pixbuf[] TEXTURE_PIXBUFS;
		public static Shader.Input[] TEXTURES;

		public static Voxmap[] 3DTEXTURE_BUFFERS;
		public static Shader.Input[] 3DTEXTURES;

		public static Gdk.Pixbuf[,] CUBEMAP_PIXBUFS_ARRAY;
		public static Shader.Input[] CUBEMAPS;

		construct
		{
			TEXTURE_PIXBUFS = new Gdk.Pixbuf[TEXTURE_IDS.length];
			TEXTURES = new Shader.Input[TEXTURE_IDS.length];

			for(int i=0; i<TEXTURE_IDS.length; i++)
			{
				Shader.Input texture = load_texture(TEXTURE_IDS[i]);
				texture.resource_index = i;
				TEXTURES[i] = texture;

				try{
					TEXTURE_PIXBUFS[i] = new Gdk.Pixbuf.from_resource(texture.resource);
				}
				catch(Error e){
					print(@"Couldn't load texture $(TEXTURE_IDS[i])\n");
				}
			}

			3DTEXTURE_BUFFERS = new Voxmap[3DTEXTURE_IDS.length];
			3DTEXTURES = new Shader.Input[3DTEXTURE_IDS.length];

			for(int i=0; i<3DTEXTURE_IDS.length; i++)
			{
				Shader.Input 3dtexture = load_3dtexture(3DTEXTURE_IDS[i]);
				3dtexture.resource_index = i;
				3DTEXTURES[i] = 3dtexture;

				try{
					uint8[] data = resources_lookup_data("/org/hasi/shady/data/shader/prefix.glsl", 0).get_data();
					3DTEXTURE_BUFFERS[i].width = (int)data[4:8];
					3DTEXTURE_BUFFERS[i].height = (int)data[8:12];
					3DTEXTURE_BUFFERS[i].depth = (int)data[12:16];
					3DTEXTURE_BUFFERS[i].channels = (int)data[16:20];
					3DTEXTURE_BUFFERS[i].voxels = data[20:-0];
				}
				catch(Error e){
					print(@"Couldn't load 3dtexture $(3DTEXTURE_IDS[i])\n");
				}
			}

			CUBEMAP_PIXBUFS_ARRAY = new Gdk.Pixbuf[CUBEMAPS.length,6];
			CUBEMAPS = new Shader.Input[CUBEMAPS.length];

			for(int i=0; i<CUBEMAP_IDS.length; i++)
			{
				Shader.Input cubemap = load_cubemap(CUBEMAP_IDS[i]);
				cubemap.resource_index = i;
				CUBEMAPS[i] = cubemap;

				try{
					for(int j=0;j<6;j++){
						CUBEMAP_PIXBUFS_ARRAY[i,j] = new Gdk.Pixbuf.from_resource(cubemap.resource.replace("$j",@"$j"));
					}
				}
				catch(Error e){
					print(@"Couldn't load cubemap $(CUBEMAP_IDS[i])\n");
				}
			}
		}

		public int texture_index_from_string(string index)
		{
			int i;
			for(i=0;i<TEXTURE_IDS.length;i++)
			{
				if(TEXTURE_IDS[i] == index)
				{
					break;
				}
			}

			if(i==TEXTURE_IDS.length)
			{
				print("Texture index not found");
			}

			return i;
		}

		public int 3dtexture_index_from_string(string index)
		{
			int i;
			for(i=0;i<3DTEXTURE_IDS.length;i++)
			{
				if(3DTEXTURE_IDS[i] == index)
				{
					break;
				}
			}

			if(i==3DTEXTURE_IDS.length)
			{
				print("3dtexture index not found");
			}

			return i;
		}

		public int cubemap_index_from_string(string index)
		{
			int i;
			for(i=0;i<CUBEMAP_IDS.length;i++)
			{
				if(CUBEMAP_IDS[i] == index)
				{
					break;
				}
			}

			if(i==CUBEMAP_IDS.length)
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

		public static Shader.Input? load_3dtexture(string texture_id)
		{
			File 3dtexture_json_file = File.new_for_uri(@"resource://$(3DTEXTURE_PREFIX)/$(texture_id).json");

			try
			{
				var 3dtexture_parser = new Json.Parser();
				3dtexture_parser.load_from_data(read_file_as_string(3dtexture_json_file), -1);

				var 3dtexture_root = 3dtexture_parser.get_root().get_object();

				Shader.Input 3dtexture = new Shader.Input();
				3dtexture.hash = 3dtexture_root.get_string_member("hash");
				3dtexture.resource = 3dtexture_root.get_string_member("resource");
				3dtexture.name = 3dtexture_root.get_string_member("name");

				return 3dtexture;
			}
			catch (Error e)
			{
				print(@"Could not load 3dtexture $(texture_id): $(e.message)\n");

				return null;
			}
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
				cubemap.hash = cubemap_root.get_string_member("hash");
				cubemap.resource = cubemap_root.get_string_member("resource");
				cubemap.name = cubemap_root.get_string_member("name");

				return cubemap;
			}
			catch (Error e)
			{
				print(@"Could not load cubemap $cubemap_id: $(e.message)\n");

				return null;
			}
		}
	}
}
