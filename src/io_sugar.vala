namespace Shady
{
	public static string read_file_as_string(File file)
	{
		DataInputStream dis = new DataInputStream(file.read());

		string file_string = "";
		string line;
		while ((line = dis.read_line()) != null)
		{
			file_string += @"$(line)\n";
		}

		return file_string;
	}
}