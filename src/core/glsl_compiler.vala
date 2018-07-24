using GL;

namespace Shady.Core
{
    public class GLSLCompiler
    {
        private static string COMPILE_ERROR_PREFIX = "ERROR: stdin:";
        private static string COMPILE_ERROR_LINE_NUMBER_SPLITTER = ": ";
        private static string COMPILE_ERROR_TOKEN_SPLITTER = " : ";

        public enum Stage
		{
			VERTEX,
			FRAGMENT,
			INVALID;

			public static Stage from_string(string type)
			{
				if (type == "vert")
				{
					return VERTEX;
				}
				else if (type == "frag")
				{
					return FRAGMENT;
				}

				return INVALID;
			}

			public string to_string()
			{
		        if (this == VERTEX)
		        {
			        return "vert";
		        }
		        else if (this == FRAGMENT)
		        {
			        return "frag";
		        }

		        return "invalid";
			}
		}

		public class CompileError
		{
		    public int line;
		    public string token;
		    public string reason;

		    public string to_string()
		    {
		        string str = @"Line $line";

		        if (token != "")
		        {
		            str += @" (near $token)";
		        }

		        str += @": $reason";

		        return str;
		    }
		}

		public delegate void CompilationFinishedCallback(GLchar[] spirv, CompileError[] compile_errors, bool success);

        public GLSLCompiler()
        {
        }

        public void compile(Stage stage, string source, CompilationFinishedCallback callback)
        {
            string spawn_args[] = { "glslangValidator", "--stdin", "-V", "-S", stage.to_string(), "-o", "/dev/stderr", null };

            Pid child_pid;
            int standard_in, standard_out, standard_error;
            size_t bytes_written;

            Array<GLchar> spirv_buffer = new Array<GLchar>();
            Array<CompileError> compile_errors = new Array<CompileError>();
            bool success = true;

            try
            {
                Process.spawn_async_with_pipes("/",
                                               spawn_args,
                                               Environ.get(),
                                               SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                                               null,
                                               out child_pid,
                                               out standard_in,
                                               out standard_out,
                                               out standard_error);
            }
            catch (Error e)
            {
                print(@"Error: $(e.message)");
            }

            IOChannel input = new IOChannel.unix_new(standard_in);
            input.write_chars(source.to_utf8(), out bytes_written);
            if (source.length != bytes_written)
            {
                print("Error: Could not write full shader source code to stdin\n");
            }

            input.shutdown(true);

            IOChannel output = new IOChannel.unix_new(standard_out);
            output.add_watch(IOCondition.IN | IOCondition.HUP, (channel, condition) =>
            {
                if (condition == IOCondition.HUP)
                {
			        return false;
		        }

		        string line;

		        try
		        {
			        IOStatus status = channel.read_line(out line, null, null);

                    if (line.has_prefix(COMPILE_ERROR_PREFIX))
                    {
                        CompileError compile_error = new CompileError();

			            string clean_error = line.split(COMPILE_ERROR_PREFIX, 2)[1];
			            string[] split_error = clean_error.split(COMPILE_ERROR_LINE_NUMBER_SPLITTER, 2);

			            compile_error.line = int.parse(split_error[0].strip());
			            string rest_error = split_error[1].strip();

			            string[] split_rest_error = rest_error.split(COMPILE_ERROR_TOKEN_SPLITTER, 2);

			            compile_error.token = split_rest_error[0][1:split_rest_error[0].length - 1].strip();
			            compile_error.reason = split_rest_error[1].strip();

                        if (!("compilation terminated" in rest_error))
                        {
			                compile_errors.append_val(compile_error);
			            }

			            success = false;
			        }

			        if (status == IOStatus.EOF)
			        {
				        return false;
			        }

			        return true;
		        }
		        catch (IOChannelError e)
		        {
		            success = false;
			        print("Error: %s\n", e.message);

			        return false;
		        }
		        catch (ConvertError e)
		        {
		            success = false;
			        print("Error: %s\n", e.message);

			        return false;
		        }

	            return false;
            });

            IOChannel error = new IOChannel.unix_new(standard_error);
            error.set_encoding(null);
            error.add_watch(IOCondition.IN | IOCondition.HUP, (channel, condition) =>
            {
                if (condition == IOCondition.HUP)
                {
			        return false;
		        }

		        char buffer[1024];
		        size_t bytes_read;

		        try
		        {
			        IOStatus status = channel.read_chars(buffer, out bytes_read);
			        spirv_buffer.append_vals(buffer, (uint) bytes_read);

			        if (status == IOStatus.EOF)
			        {
				        return false;
			        }

			        return true;
		        }
		        catch (IOChannelError e)
		        {
		            success = false;
			        print("Error: %s\n", e.message);

			        return false;
		        }
		        catch (ConvertError e)
		        {
		            success = false;
			        print("Error: %s\n", e.message);

			        return false;
		        }
            });

            ChildWatch.add(child_pid, (pid, status) =>
            {
                callback(spirv_buffer.data, compile_errors.data, success);

	            Process.close_pid(pid);
            });
        }
    }
}