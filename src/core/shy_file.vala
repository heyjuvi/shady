using Shady;

namespace Shady.Core
{
    public class ShyFile
    {
        public static string FILE_EXTENSION = ".shy";

        public static Gtk.FileFilter FILE_FILTER
        {
            owned get
            {
                Gtk.FileFilter filter = new Gtk.FileFilter();
                filter.set_name("Shady shader file (*.shy)");
                filter.add_pattern("*.[Ss][Hh][Yy]");

                return filter;
            }
        }

        private File _file;

        public ShyFile.for_path(string path)
        {
            _file = File.new_for_path(path);
        }

        public ShyFile.for_file(File file)
        {
            _file = file;
        }

        public Shader? read_shader()
        {
            Shader shader = new Shader();

            try
            {
                var parser = new Json.Parser();
                parser.load_from_data(read_file_as_string(_file), -1);

                var root = parser.get_root().get_object();

                shader.shader_name = root.get_string_member("name");
                shader.description = root.get_string_member("description");

                var renderpasses = root.get_array_member("renderpasses");
                foreach (var renderpass_node in renderpasses.get_elements())
                {
                    Shader.Renderpass renderpass = new Shader.Renderpass();

                    renderpass.type = Shader.RenderpassType.from_string(renderpass_node.get_object().get_string_member("type"));
                    renderpass.renderpass_name = renderpass_node.get_object().get_string_member("name");
                    renderpass.code = renderpass_node.get_object().get_string_member("code");

                    var inputs = renderpass_node.get_object().get_array_member("inputs");
                    foreach (var input_node in inputs.get_elements())
                    {
                        Shader.Input input = new Shader.Input();

                        input.type = Shader.InputType.from_string(input_node.get_object().get_string_member("type"));
                        input.channel = (int) input_node.get_object().get_int_member("channel");

                        var sampler_node = input_node.get_object().get_object_member("sampler");

                        input.sampler = new Shader.Sampler();
                        input.sampler.filter = Shader.FilterMode.from_string(sampler_node.get_string_member("filter"));
                        input.sampler.wrap = Shader.WrapMode.from_string(sampler_node.get_string_member("wrap"));
                        input.sampler.v_flip = sampler_node.get_boolean_member("vflip");

                        if (input.type != Shader.InputType.KEYBOARD &&
                            input.type != Shader.InputType.WEBCAM &&
                            input.type != Shader.InputType.MICROPHONE)
                        {
                            string resource = null;
                            if (input.type != Shader.InputType.BUFFER)
                            {
                                resource = input_node.get_object().get_string_member("resource");
                            }

                            // TODO: we need to check, if the resource is an uri
                            //       handle this case

                            if (input.type == Shader.InputType.TEXTURE)
                            {
                                input.assign_content(ShadertoyResourceManager.get_texture_by_name(resource));
                            }

                            if (input.type == Shader.InputType.3DTEXTURE)
                            {
                                input.assign_content(ShadertoyResourceManager.get_3dtexture_by_name(resource));
                            }

                            if (input.type == Shader.InputType.CUBEMAP)
                            {
                                input.assign_content(ShadertoyResourceManager.get_cubemap_by_name(resource));
                            }

                            if (input.type == Shader.InputType.VIDEO)
                            {
                                // TODO
                            }

                            if (input.type == Shader.InputType.MUSIC)
                            {
                                // TODO
                            }

                            if (input.type == Shader.InputType.BUFFER)
                            {
                                input.id = (int) input_node.get_object().get_int_member("id");
                            }
                        }

                        renderpass.inputs.append_val(input);
                    }

                    var outputs = renderpass_node.get_object().get_array_member("outputs");
                    foreach (var output_node in outputs.get_elements())
                    {
                        Shader.Output output = new Shader.Output();

                        output.id = (int) output_node.get_object().get_int_member("id");

                        renderpass.outputs.append_val(output);
                    }

                    shader.renderpasses.append_val(renderpass);
                }

                return shader;
            }
            catch (Error e)
            {
            }

            return null;
        }

        public void write_shader(Shader shader)
        {
            Json.Builder builder = new Json.Builder();

            builder.begin_object();

            builder.set_member_name("name");
            builder.add_string_value(shader.shader_name);

            builder.set_member_name("description");
            builder.add_string_value(shader.description);

            builder.set_member_name("renderpasses");
            builder.begin_array();

            for (int i = 0; i < shader.renderpasses.length; i++)
            {
                var renderpass = shader.renderpasses.index(i);

                builder.begin_object();

                builder.set_member_name("type");
                builder.add_string_value(renderpass.type.to_string());

                builder.set_member_name("name");
                builder.add_string_value(renderpass.renderpass_name);

                builder.set_member_name("code");
                builder.add_string_value(renderpass.code);

                builder.set_member_name("inputs");
                builder.begin_array();

                for (int j = 0; j < renderpass.inputs.length; j++)
                {
                    var input = renderpass.inputs.index(j);

                    if (input.type == Shader.InputType.NONE)
                    {
                        continue;
                    }

                    builder.begin_object();

                    builder.set_member_name("type");
                    builder.add_string_value(input.type.to_string());

                    builder.set_member_name("channel");
                    builder.add_int_value(input.channel);

                    if (input.type == Shader.InputType.BUFFER)
                    {
                        builder.set_member_name("id");
                        builder.add_int_value(input.id);
                    }
                    else
                    {
                        builder.set_member_name("resource");
                        builder.add_string_value(input.input_name);
                    }

                    builder.set_member_name("sampler");
                    builder.begin_object();

                    builder.set_member_name("filter");
                    builder.add_string_value(input.sampler.filter.to_string());

                    builder.set_member_name("wrap");
                    builder.add_string_value(input.sampler.wrap.to_string());

                    builder.set_member_name("vflip");
                    builder.add_boolean_value(input.sampler.v_flip);

                    builder.end_object();

                    builder.end_object();
                }

                builder.end_array();

                builder.set_member_name("outputs");
                builder.begin_array();

                for (int j = 0; j < renderpass.outputs.length; j++)
                {
                    var output = renderpass.outputs.index(j);

                    builder.begin_object();

                    builder.set_member_name("id");
                    builder.add_int_value(output.id);

                    builder.end_object();
                }

                builder.end_array();

                builder.end_object();
            }

            builder.end_array();

            builder.end_object();

            Json.Generator generator = new Json.Generator();
            Json.Node root = builder.get_root();
            generator.set_root(root);
            generator.set_pretty(true);

            write_file_for_string(_file, generator.to_data(null));
        }
    }
}
