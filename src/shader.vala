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
			public int id;
			public int channel;
			public InputType type;
			public Sampler sampler;
			public string hash;
			public string resource;
			public string name;
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
		}

		public class Sampler
		{
			public FilterMode filter;
			public WrapMode wrap;
			public bool v_flip;
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
