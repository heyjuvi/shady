namespace Shady.Core
{
    public class GLSLReference
    {
        public class Synopsis
        {
            public class FunctionPrototype
            {
                public class ParameterDefinition
                {
                    public string name;
                    public string type;
                }

                public FunctionPrototype()
                {
                    parameter_definitions = new Array<ParameterDefinition>();
                }

                public string name;
                public string return_type;

                public Array<ParameterDefinition> parameter_definitions;

                public string get_markup()
                {
                    string markup = @"<b>$return_type</b> $name(";
                    for (int i = 0; i < parameter_definitions.length; i++)
                    {
                        markup += @"<b>$(parameter_definitions.index(i).type)</b> " +
                                  @"$(parameter_definitions.index(i).name)";

                        if (i != parameter_definitions.length - 1)
                        {
                            markup += ", ";
                        }
                    }

                    markup += ")";

                    return markup;
                }
            }

            public Synopsis()
            {
                prototypes = new Array<FunctionPrototype>();
            }

            public Array<FunctionPrototype> prototypes;

            public string get_markup()
            {
                string markup = "";
                for (int i = 0; i < prototypes.length; i++)
                {
                    markup += @"$(prototypes.index(i).get_markup())\n";
                }

                return markup;
            }
        }

        public class Parameters
        {
            public class ParameterDescription
            {
                public string name;
                public string description;

                public string get_markup()
                {
                    string markup_description = description.replace("<", "&lt;").replace(">", "&gt;");
                    string markup = @"<i>$name</i>: $markup_description";

                    return markup;
                }
            }

            public Parameters()
            {
                parameter_descriptions = new Array<ParameterDescription>();
            }

            public Array<ParameterDescription> parameter_descriptions;

            public string get_markup()
            {
                string markup = "";
                for (int i = 0; i < parameter_descriptions.length; i++)
                {
                    markup += @"$(parameter_descriptions.index(i).get_markup())\n";
                }

                return markup;
            }
        }

        public GLSLReference()
        {
            synopsis = new Synopsis();
            parameters = new Parameters();

            name = "";
            purpose = "";
            description = "";
            seealso = "";
        }

        public string name;
        public string purpose;
        public Synopsis synopsis;
        public Parameters parameters;
        public string description;
        public string seealso;

        public string get_markup()
        {
            string markup_description = description.replace("<", "&lt;").replace(">", "&gt;");
            string markup = "";

            markup += @"<b>$name</b> ($purpose)\n\n";
            markup += @"$(synopsis.get_markup())\n";
            markup += @"$(parameters.get_markup())\n";
            markup += @"$markup_description\n\n";
            markup += @"See also: $seealso";

            return markup;
        }

        public string get_short_markup()
        {
            string markup = "";

            markup += @"<b>$name</b> ($purpose)\n\n";
            markup += @"$(synopsis.get_markup())\n";
            markup += @"$(parameters.get_markup())";

            return markup[0:markup.length - 1];
        }
    }

    public class GLSLReferenceParser
    {
        public GLSLReferenceParser()
        {
        }

        public GLSLReference get_reference_for(string name)
        {
            string xml_data = read_file_as_string(File.new_for_uri(@"resource:///org/hasi/shady/data/refpages/es3.0/$name.xml"));
            if (xml_data == "")
            {
                return (GLSLReference) null;
            }

            Xml.Doc *doc = Xml.Parser.read_memory(xml_data,
                                                  xml_data.length,
                                                  null,
                                                  "UTF-8",
                                                  Xml.ParserOption.NOENT | Xml.ParserOption.NONET | Xml.ParserOption.RECOVER | Xml.ParserOption.NOERROR | Xml.ParserOption.NOWARNING);
            if (doc == null)
            {
                // bad
                return (GLSLReference) null;
            }

            Xml.Node *root = doc->get_root_element();
            if (root == null)
            {
                delete doc;

                // bad
                return (GLSLReference) null;
            }

            GLSLReference reference = new GLSLReference();

            parse_root(reference, root);

            return reference;
        }

        private void parse_root(GLSLReference reference, Xml.Node *node)
        {
            for (Xml.Node *iter = node->children; iter != null; iter = iter->next)
            {
                if (iter->type != Xml.ElementType.ELEMENT_NODE)
                {
                    continue;
                }

                string node_name = iter->name;
                //string node_content = iter->get_content();
                HashTable<string, string> node_properties = new HashTable<string, string>(str_hash, str_equal);
                //print(node_content);

                for (Xml.Attr* prop = iter->properties; prop != null; prop = prop->next)
                {
                    string attr_name = prop->name;
                    string attr_content = prop->children->content;

                    node_properties.insert(attr_name, attr_content);
                }

                if (node_name == "refnamediv")
                {
                    parse_name(reference, iter);
                }
                else if (node_name == "refsynopsisdiv")
                {
                    parse_synopsis(reference, iter);
                }
                else if (node_name == "refsect1")
                {
                    if ("id" in node_properties)
                    {
                        string section_id = node_properties["id"];

                        if (section_id == "parameters")
                        {
                            parse_parameters(reference, iter);
                        }
                        else if (section_id == "description")
                        {
                            parse_description(reference, iter);
                        }
                        else if (section_id == "seealso")
                        {
                            parse_seealso(reference, iter);
                        }
                    }
                }
            }
        }

        private void parse_name(GLSLReference reference, Xml.Node *node)
        {
            for (Xml.Node *iter = node->children; iter != null; iter = iter->next)
            {
                if (iter->type != Xml.ElementType.ELEMENT_NODE)
                {
                    continue;
                }

                string node_name = iter->name;
                string node_content = iter->get_content();

                if (node_name == "refname")
                {
                    reference.name = node_content;
                }
                else if (node_name == "refpurpose")
                {
                    reference.purpose = node_content;
                }
            }
        }

        private void parse_synopsis(GLSLReference reference, Xml.Node *node)
        {
            for (Xml.Node *iter = node->children; iter != null; iter = iter->next)
            {
                if (iter->type != Xml.ElementType.ELEMENT_NODE)
                {
                    continue;
                }

                string node_name = iter->name;
                if (node_name == "funcsynopsis")
                {
                    for (Xml.Node *syn_iter = iter->children; syn_iter != null; syn_iter = syn_iter->next)
                    {
                        string syn_node_name = syn_iter->name;
                        if (syn_node_name == "funcprototype")
                        {
                            GLSLReference.Synopsis.FunctionPrototype prototype = new GLSLReference.Synopsis.FunctionPrototype();

                            for (Xml.Node *prot_iter = syn_iter->children; prot_iter != null; prot_iter = prot_iter->next)
                            {
                                string prot_node_name = prot_iter->name;
                                string prot_node_content = prot_iter->get_content();
                                if (prot_node_name == "funcdef")
                                {
                                    string[] split_prot_node_content = prot_node_content.strip().split(" ", 2);
                                    prototype.name = split_prot_node_content[1];
                                    prototype.return_type = split_prot_node_content[0];
                                }
                                else if (prot_node_name == "paramdef")
                                {
                                    GLSLReference.Synopsis.FunctionPrototype.ParameterDefinition parameter_definition = new GLSLReference.Synopsis.FunctionPrototype.ParameterDefinition();

                                    string[] split_prot_node_content = prot_node_content.strip().split(" ", 2);
                                    parameter_definition.name = split_prot_node_content[1];
                                    parameter_definition.type = split_prot_node_content[0];

                                    prototype.parameter_definitions.append_val(parameter_definition);
                                }
                            }

                            reference.synopsis.prototypes.append_val(prototype);
                        }
                    }
                }
            }
        }

        private void parse_parameters(GLSLReference reference, Xml.Node *node)
        {
            for (Xml.Node *iter = node->children; iter != null; iter = iter->next)
            {
                if (iter->type != Xml.ElementType.ELEMENT_NODE)
                {
                    continue;
                }

                string node_name = iter->name;
                if (node_name == "variablelist")
                {
                    for (Xml.Node *list_iter = iter->children; list_iter != null; list_iter = list_iter->next)
                    {
                        string list_node_name = list_iter->name;
                        if (list_node_name == "varlistentry")
                        {
                            GLSLReference.Parameters.ParameterDescription parameter_description = new GLSLReference.Parameters.ParameterDescription();

                            for (Xml.Node *entry_iter = list_iter->children; entry_iter != null; entry_iter = entry_iter->next)
                            {
                                string entry_node_name = entry_iter->name;
                                string entry_node_content = entry_iter->get_content();
                                if (entry_node_name == "term")
                                {
                                    parameter_description.name = entry_node_content.strip();
                                }
                                else if (entry_node_name == "listitem")
                                {
                                    parameter_description.description = "";

                                    for (Xml.Node *item_iter = entry_iter->children; item_iter != null; item_iter = item_iter->next)
                                    {
                                        string item_node_name = item_iter->name;
                                        string item_node_content = item_iter->get_content();
                                        if (item_node_name == "para")
                                        {
                                            parameter_description.description += item_node_content.strip();
                                        }
                                    }
                                }
                            }

                            reference.parameters.parameter_descriptions.append_val(parameter_description);
                        }
                    }
                }
            }
        }

        private void parse_description(GLSLReference reference, Xml.Node *node)
        {
            for (Xml.Node *iter = node->children; iter != null; iter = iter->next)
            {
                if (iter->type != Xml.ElementType.ELEMENT_NODE)
                {
                    continue;
                }

                string node_name = iter->name;
                string node_content = iter->get_content();
                if (node_name == "para")
                {
                    string[] split_content = node_content.split("\n");
                    string[] new_content = {};
                    for (int i = 0; i < split_content.length; i++)
                    {
                        if (split_content[i].strip() != "")
                        {
                            new_content += split_content[i].strip();
                        }
                    }

                    string clean_content = string.joinv("\n", new_content);

                    reference.description += clean_content;

                    if (iter->next != null)
                    {
                        reference.description += "\n\n";
                    }
                }
            }

            reference.description = reference.description[0:reference.description.length - 2];
        }

        private void parse_seealso(GLSLReference reference, Xml.Node *node)
        {
            for (Xml.Node *iter = node->children; iter != null; iter = iter->next)
            {
                if (iter->type != Xml.ElementType.ELEMENT_NODE)
                {
                    continue;
                }

                string node_name = iter->name;
                string node_content = iter->get_content();
                if (node_name == "para")
                {
                    string[] split_content = node_content.split("\n");
                    string[] new_content = {};
                    for (int i = 0; i < split_content.length; i++)
                    {
                        if (split_content[i].strip() != "")
                        {
                            new_content += split_content[i].strip();
                        }
                    }

                    string clean_content = string.joinv(" ", new_content);

                    reference.seealso = clean_content;
                }
            }
        }
    }
}
