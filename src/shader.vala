namespace Shady
{
	public class Shader
	{
		public class Buffer
		{
			public string name;
			public string type;
			public string code;
		}

		public class Texture
		{
			public string hash;
			public string resource;
			public string name;
		}

		public string name;
		public string description;
		public string author;
		public int likes;
		public int views;

		public HashTable<string, Buffer> buffers = new HashTable<string, Buffer>(str_hash, str_equal);
	}
}
