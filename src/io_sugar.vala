namespace Shady
{
	public static string read_file_as_string(File file)
	{
		try
		{
			DataInputStream dis = new DataInputStream(file.read());

			string file_string = "";
			string line;
			while ((line = dis.read_line()) != null)
			{
				file_string += @"$(line)\n";
			}

			return file_string[0:file_string.length - 1];
		}
		catch (Error e)
		{
			//print(@"Couldn't load $(file.get_path())\n");
			return "";
		}
	}

	public static void write_file_for_string(File file, string str)
	{
	    try
		{
			DataOutputStream dis = new DataOutputStream(file.replace(null, false, FileCreateFlags.REPLACE_DESTINATION));

			dis.put_string(str);
		}
		catch (Error e)
		{
		}
	}
}
