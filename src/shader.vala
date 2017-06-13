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
			MUSIC;

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

				// that should be implemented otherwise
				return NONE;
			}
		}

		public class Input
		{
			public int id;
			public int channel;
			public InputType type;
			public string hash;
			public string resource;
			public string name;
		}

		public class Output
		{
		}

		public enum FilterMode
		{
			LINEAR,
			NEAREST;

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

				// that should be implemented otherwise
				return LINEAR;
			}
		}

		public enum WrapMode
		{
			CLAMP,
			REPEAT;

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

				// that should be implemented otherwise
				return CLAMP;
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
			AUDIO,
			IMAGE,
			BUFFER;

			public static RenderpassType from_string(string type)
			{
				if (type == "audio")
				{
					return AUDIO;
				}
				else if (type == "image")
				{
					return IMAGE;
				}
				else if (type == "buffer")
				{
					return BUFFER;
				}

				// that should be implemented otherwise
				return BUFFER;
			}
		}

		public class Renderpass : Output
		{
			public string code;
			public RenderpassType type;
			public string name;

			public Array<int> input_ids = new Array<int>();
			public HashTable<int, Sampler> samplers = new HashTable<int, Sampler>(direct_hash, direct_equal);
		}

		public string name;
		public string description;
		public string author;
		public int likes;
		public int views;

		public Array<Renderpass> renderpasses = new Array<Renderpass>();
	}
}
