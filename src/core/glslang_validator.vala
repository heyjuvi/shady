using GL;

namespace Shady.Core
{
    public class GLSlangValidator
    {
        private static string COMPILE_ERROR_PREFIX = "ERROR: 0:";
        private static string COMPILE_ERROR_LINE_NUMBER_SPLITTER = ": ";
        private static string COMPILE_ERROR_TOKEN_SPLITTER = " : ";

		public class CompileError
		{
		    public int line;
		    public Array<string> tokens;
		    public Array<string> reasons;

		    public CompileError()
		    {
		        tokens = new Array<string>();
		        reasons = new Array<string>();
		    }

		    public string to_string()
		    {
		        string str = "";

		        for (int i = 0; i < tokens.length && i < reasons.length; i++)
		        {
		            str += @"Line $line";

		            if (tokens.index(i) != "")
		            {
		                str += @" (near $(tokens.index(i)))";
		            }

		            str += @": $(reasons.index(i))\n";
		        }

		        return str[0:str.length - 1];
		    }

		    public string to_string_without_lines()
		    {
		        string str = "";

		        for (int i = 0; i < tokens.length && i < reasons.length; i++)
		        {
		            if (tokens.index(i) != "")
		            {
		                str += @"near $(tokens.index(i)): ";
		            }

		            str += @"$(reasons.index(i))\n";
		        }

		        return str[0:str.length - 1];
		    }
		}

		public delegate void CompilationFinishedCallback(CompileError[] compile_errors, bool success);

		static construct
		{
		    GLSlang.initialize();
		}

        public GLSlangValidator()
        {
        }

        private void take_line_apart(string line, out int line_number, out string token, out string reason)
        {
            string clean_error = line.split(COMPILE_ERROR_PREFIX, 2)[1];

            string[] split_error = clean_error.split(COMPILE_ERROR_LINE_NUMBER_SPLITTER, 2);

            line_number = int.parse(split_error[0].strip());
            string rest_error = split_error[1].strip();

            string[] split_rest_error = rest_error.split(COMPILE_ERROR_TOKEN_SPLITTER, 2);

            token = split_rest_error[0][1:split_rest_error[0].length - 1].strip();
            reason = split_rest_error[1].strip();
        }

        public bool validate(string source, CompilationFinishedCallback callback)
        {
            bool success = true;
            Array<CompileError> compile_errors = new Array<CompileError>();

            string info_log;
            GLSlang.validate(source, 110, out info_log);

            string[] split_info_log = info_log.split("\n");

			for (int i = 0; i < split_info_log.length; i++)
			{
				if (split_info_log[i].has_prefix(COMPILE_ERROR_PREFIX))
				{
					if (!("compilation errors" in split_info_log[i]))
					{
						CompileError compile_error = new CompileError();

						string token, reason;

						take_line_apart(split_info_log[i], out compile_error.line, out token, out reason);

						int line_number = compile_error.line;

						bool error_ended = false;
						while (!error_ended)
						{
							compile_error.tokens.append_val(token);
							compile_error.reasons.append_val(reason);

							if (i != split_info_log.length &&
								split_info_log[i + 1].has_prefix(COMPILE_ERROR_PREFIX) &&
								!("compilation errors" in split_info_log[i + 1]))
							{
								take_line_apart(split_info_log[i], out line_number, out token, out reason);

								if (line_number == compile_error.line)
								{
									i++;
								}
								else
								{
									error_ended = true;
								}
							}
							else
							{
								error_ended = true;
							}
						}

						compile_errors.append_val(compile_error);
					}

					success = false;
				}
			}

            callback(compile_errors.data, success);

            return true;
        }
    }
}
