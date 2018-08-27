namespace Shady
{
	public class Shader
	{
		public enum InputType
		{
			NONE,
			KEYBOARD,
			WEBCAM,
			MICROPHONE,
			SOUNDCLOUD,
			BUFFER,
			TEXTURE,
			3DTEXTURE,
			CUBEMAP,
			VIDEO,
			MUSIC,
			INVALID;

			public static InputType from_string(string type)
			{
				if (type == "none")
				{
					return NONE;
				}
				else if (type == "keyboard")
				{
					return KEYBOARD;
				}
				else if (type == "webcam")
				{
					return WEBCAM;
				}
				else if (type == "microphone")
				{
					return MICROPHONE;
				}
				else if (type == "soundcloud")
				{
					return SOUNDCLOUD;
				}
				else if (type == "buffer")
				{
					return BUFFER;
				}
				else if (type == "texture")
				{
					return TEXTURE;
				}
				else if (type == "3dtexture")
				{
					return 3DTEXTURE;
				}
				else if (type == "cubemap")
				{
					return CUBEMAP;
				}
				else if (type == "video")
				{
					return VIDEO;
				}
				else if (type == "music")
				{
					return MUSIC;
				}

				return INVALID;
			}
		}

		public class Input
		{
			public int id = -1;
			public int channel = -1;
			public InputType type;
			public Sampler sampler = new Sampler();
			public string hash;
			public int n_channels;
			public string name;
			public string resource;
			public int resource_index;

			public void assign(Input other)
			{
			    id = other.id;
			    channel = other.channel;
			    type = other.type;
			    sampler = other.sampler;
			    hash = other.hash;
			    name = other.name;
			    resource = other.resource;
			    resource_index = other.resource_index;
			}

			public void assign_content(Input other)
			{
			    id = other.id;
			    type = other.type;
			    hash = other.hash;
			    name = other.name;
			    resource = other.resource;
			    resource_index = other.resource_index;
			}

			public string to_string()
			{
			    return @"{ \"id\": $id, \"channel\": $channel, \"type\": \"$type\", \"sampler\": \"$sampler\", \"hash\": \"$hash\", \"name\": \"$name\", \"resource\": \"$resource\", \"resource_index\": $resource_index";
			}
		}

		public class Output
		{
			public int id;
			public int channel;
		}

		public enum FilterMode
		{
			LINEAR,
			NEAREST,
			MIPMAP,
			INVALID;

			public static FilterMode from_string(string mode)
			{
				if (mode == "linear")
				{
					return LINEAR;
				}
				else if (mode == "nearest")
				{
					return NEAREST;
				}
				else if (mode == "mipmap")
				{
					return MIPMAP;
				}

				return INVALID;
			}

			public string to_string()
			{
			    if (this == LINEAR)
			    {
			        return "linear";
			    }
			    else if (this == NEAREST)
			    {
			        return "nearest";
			    }
			    else if (this == MIPMAP)
			    {
			        return "mipmap";
			    }

			    return "invalid";
			}
		}

		public enum WrapMode
		{
			CLAMP,
			REPEAT,
			INVALID;

			public static WrapMode from_string(string mode)
			{
				if (mode == "clamp")
				{
					return CLAMP;
				}
				else if (mode == "repeat")
				{
					return REPEAT;
				}

				return INVALID;
			}

			public string to_string()
			{
				if (this == CLAMP)
				{
					return "clamp";
				}
				else if (this == REPEAT)
				{
					return "repeat";
				}

				return "invalid";
			}
		}

		public class Sampler
		{
			public FilterMode filter = FilterMode.MIPMAP;
			public WrapMode wrap = WrapMode.REPEAT;
			public bool v_flip = false;

			public string to_string()
			{
			    return @"{ \"filter\": \"$filter\", \"wrap\": \"$wrap\", \"v_flip\": $v_flip }";
			}
		}

		public enum RenderpassType
		{
			SOUND,
			IMAGE,
			BUFFER,
			INVALID;

			public static RenderpassType from_string(string type)
			{
				if (type == "sound")
				{
					return SOUND;
				}
				else if (type == "image")
				{
					return IMAGE;
				}
				else if (type == "buffer")
				{
					return BUFFER;
				}

				return INVALID;
			}
		}

		public class Renderpass
		{
			public string code;
			public RenderpassType type;
			public string name;

			public Array<Input> inputs = new Array<Input>();
			public Array<Output> outputs = new Array<Output>();
		}

		public string name;
		public string description;
		public string author;
		public int likes;
		public int views;

		public Array<Renderpass> renderpasses = new Array<Renderpass>();
	}
}
