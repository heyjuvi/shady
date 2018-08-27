namespace Shady.Core
{
    public class GLSLMinifier
    {
        public GLSLMinifier()
        {
        }

        public string minify_kindly(string glsl)
        {
            /*
             * Impudently stolen from Shadertoy.com (thx!)
             */
            string str = glsl;

            str = remove_comments(str);
            str = replace_chars(str);
            str = remove_multi_spaces(str);
            str = remove_single_spaces(str);
            str = remove_empty_lines(str);

            return str;
        }

        private bool is_space(string str, int i)
        {
            return str[i] == ' ' || str[i] == '\t';
        }

        private bool is_line(string str, int i)
        {
            return str[i] == '\n';
        }

        private string remove_comments(string str)
        {
            string dst = "";
            int num = str.length;
            int state = 0;

            for (int i = 0; i < num; i++)
            {
                if (i <= num - 2)
                {
                    if (state == 0 && str[i] == '/' && str[i + 1] == '*')
                    {
                        state = 1;
                        i += 1;
                        continue;
                    }

                    if (state == 0 && str[i] == '/' && str[i + 1]== '/')
                    {
                        state = 2;
                        i+=1;
                        continue;
                    }
                    if (state == 1 && str[i] == '*' && str[i + 1] == '/')
                    {
                        dst += " ";
                        state = 0;
                        i += 1;
                        continue;
                    }
                    if (state ==2 && (str[i] == '\r' || str[i] == '\n'))
                    {
                        state = 0;
                        continue;
                    }
                }

                if (state == 0)
                {
                    dst = dst + str[i].to_string();
                }
            }

            return dst;
        }

        private string replace_chars(string str)
        {
            string dst = "";
            int num = str.length;
            bool is_preprocessor = false;

            for (int i = 0; i < num; i++)
            {
                if (str[i] == '#')
                {
                    is_preprocessor = true;
                }
                else if (str[i] == '\n')
                {
                    if (is_preprocessor)
                    {
                        is_preprocessor = false;
                    }
                    else
                    {
                        dst = dst + " ";
                        continue;
                    }
                }
                else if (str[i] == '\r')
                {
                    dst = dst + " ";
                    continue;
                }
                else if (str[i] == '\t')
                {
                    dst = dst + " ";
                    continue;
                }
                else if (i < num - 1 && str[i] == '\\' && str[i+1] == '\n')
                {
                    i += 1;
                    continue;
                }

                dst = dst + str[i].to_string();
            }

            return dst;
        }

        private string remove_multi_spaces(string str)
        {
            string dst = "";
            int num = str.length;

            for (int i = 0; i < num; i++)
            {
                if (is_space(str, i) && i == num - 1)
                {
                    continue;
                }
                if (is_space(str, i) && is_line(str,i-1) )
                {
                    continue;
                }
                if (is_space(str, i) && is_line(str, i + 1))
                {
                    continue;
                }
                if (is_space(str, i) && is_space(str, i + 1))
                {
                    continue;
                }

                dst = dst + str[i].to_string();
            }

            return dst;
        }

        private string remove_single_spaces(string str)
        {
            string dst = "";
            int num = str.length;

            for (int i = 0; i < num; i++)
            {
                bool iss = is_space(str, i);

                if (i == 0 && iss)
                {
                    continue;
                }

                if (i > 0)
                {
                    if (iss && (str[i - 1] == ';'  ||
                                str[i - 1] == ','  ||
                                str[i - 1] == '}'  ||
                                str[i - 1] == '{'  ||
                                str[i - 1] == '('  ||
                                str[i - 1] == ')'  ||
                                str[i - 1] == '+'  ||
                                str[i - 1] == '-'  ||
                                str[i - 1] == '*'  ||
                                str[i - 1] == '/'  ||
                                str[i - 1] == '?'  ||
                                str[i - 1] == '<'  ||
                                str[i - 1] == '>'  ||
                                str[i - 1] == '['  ||
                                str[i - 1] == ']'  ||
                                str[i - 1] == ':'  ||
                                str[i - 1] == '='  ||
                                str[i - 1] == '^'  ||
                                str[i - 1] == '%'  ||
                                str[i - 1] == '\n' ||
                                str[i - 1] == '\r'))
                    {
                        continue;
                    }
                }

                if (i > 1)
                {
                    if (iss && (str[i - 1] == '&' &&
                                str[i - 2] == '&'))
                    {
                        continue;
                    }

                    if (iss && (str[i - 1] == '|' &&
                                str[i - 2] == '|'))
                    {
                        continue;
                    }

                    if (iss && (str[i - 1] == '^' &&
                                str[i - 2] == '^'))
                    {
                        continue;
                    }

                    if (iss && (str[i - 1] == '!' &&
                                str[i - 2] == '='))
                    {
                        continue;
                    }

                    if (iss && (str[i - 1] == '=' &&
                                str[i - 2] == '='))
                    {
                        continue;
                    }
                }

                if (iss && (str[i + 1] == ';'  ||
                            str[i + 1] == ','  ||
                            str[i + 1] == '}'  ||
                            str[i + 1] == '{'  ||
                            str[i + 1] == '('  ||
                            str[i + 1] == ')'  ||
                            str[i + 1] == '+'  ||
                            str[i + 1] == '-'  ||
                            str[i + 1] == '*'  ||
                            str[i + 1] == '/'  ||
                            str[i + 1] == '?'  ||
                            str[i + 1] == '<'  ||
                            str[i + 1] == '>'  ||
                            str[i + 1] == '['  ||
                            str[i + 1] == ']'  ||
                            str[i + 1] == ':'  ||
                            str[i + 1] == '='  ||
                            str[i + 1] == '^'  ||
                            str[i + 1] == '%'  ||
                            str[i + 1] == '\n' ||
                            str[i + 1] == '\r'))
                {
                    continue;
                }

                if (i < num - 2)
                {
                    if (iss && (str[i + 1] == '&' &&
                                str[i + 2] == '&'))
                    {
                        continue;
                    }

                    if (iss && (str[i + 1] == '|' &&
                                str[i + 2] == '|'))
                    {
                        continue;
                    }

                    if (iss && (str[i + 1] == '^' &&
                                str[i + 2] == '^'))
                    {
                        continue;
                    }

                    if (iss && (str[i + 1] == '!' &&
                                str[i + 2] == '='))
                    {
                        continue;
                    }

                    if (iss && (str[i + 1] == '=' &&
                                str[i + 2] == '='))
                    {
                        continue;
                    }
                }

                dst = dst + str[i].to_string();
            }

            return dst;
        }

        private string remove_empty_lines(string str)
        {
            string dst = "";
            int num = str.length;
            bool is_preprocessor = false;

            for (int i = 0; i < num; i++)
            {
                if (str[i] == '#')
                {
                    is_preprocessor = true;
                }

                bool is_destroyable_char = is_line(str, i);

                if (is_destroyable_char && !is_preprocessor)
                {
                    continue;
                }

                if (is_destroyable_char && is_preprocessor)
                {
                    is_preprocessor = false;
                }

                dst = dst + str[i].to_string();
            }

            return dst;
        }
    }
}