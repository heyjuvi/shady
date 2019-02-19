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

			public string to_string()
			{
			    if (this == NONE)
			    {
			        return "none";
			    }
			    else if (this == KEYBOARD)
			    {
			        return "keyboard";
			    }
			    else if (this == WEBCAM)
			    {
			        return "webcam";
			    }
			    else if (this == MICROPHONE)
			    {
			        return "microphone";
			    }
			    else if (this == SOUNDCLOUD)
			    {
			        return "soundcloud";
			    }
			    else if (this == BUFFER)
			    {
			        return "buffer";
			    }
			    else if (this == TEXTURE)
			    {
			        return "texture";
			    }
			    else if (this == 3DTEXTURE)
			    {
			        return "3dtexture";
			    }
			    else if (this == CUBEMAP)
			    {
			        return "cubemap";
			    }
			    else if (this == VIDEO)
			    {
			        return "video";
			    }
			    else if (this == MUSIC)
			    {
			        return "music";
			    }

			    return "invalid";
			}
		}

		public class Input
		{
		    public static Input NO_INPUT = new Input();

			public int id = -1;
			public int channel = -1;
			public InputType type = InputType.NONE;
			public Sampler sampler = new Sampler();
			public string hash = "";
			public int n_channels = 0;
			public string name = "";
			public string resource = "";
			public int resource_index = 0;

			public void assign(Input other)
			{
			    id = other.id;
			    channel = other.channel;
			    type = other.type;
			    sampler = other.sampler;
			    hash = other.hash;
				n_channels = other.n_channels;
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

			public string to_string()
			{
				if (this == SOUND)
				{
					return "sound";
				}
				else if (this == IMAGE)
				{
					return "image";
				}
				else if (this == BUFFER)
				{
					return "buffer";
				}

				return "invalid";
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

		public Renderpass? get_renderpass_by_name(string name)
		{
		    for (int i = 0; i < renderpasses.length; i++)
		    {
		        if (renderpasses.index(i).name == name)
		        {
		            return renderpasses.index(i);
		        }
		    }

		    return null;
		}
	}
}
