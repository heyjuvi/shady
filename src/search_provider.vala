namespace Shady
{
    [DBus (name = "org.gnome.Shell.SearchProvider2")]
    public class SearchProvider : Object
    {
        private static const uint STABILIZING_TIME = 500000;

        [DBus (visible = false)]
        public signal void activate(string shader_id);

        private Soup.Session _search_session = new Soup.Session();
        private HashTable<string, string> _current_metas = null;

        private async string[] search_shaders(string search_string)
        {
			string search_uri = @"https://www.shadertoy.com/api/v1/shaders/query/$(search_string)?from=0&num=5&key=$(ShadertoySearch.API_KEY)";
			var search_message = new Soup.Message("GET", search_uri);
			InputStream search_stream;

            try
            {
                search_stream = yield _search_session.send_async(search_message);
            }
            catch (Error e)
			{
			    stderr.printf(@"returning {} ($(e.message))\n");
				return {};
			}

			GenericArray<string> result_ids = new GenericArray<string>();

			try
			{
				var search_parser = new Json.Parser();
				yield search_parser.load_from_stream_async(search_stream);

				var search_root = search_parser.get_root().get_object();

				uint64 num_shaders = search_root.get_int_member("Shaders");
				if (num_shaders == 0)
				{
                    return result_ids.data;
				}

				var results = search_root.get_array_member("Results");
				foreach (var result_node in results.get_elements())
				{
				    result_ids.add(result_node.get_string());
				}

				return result_ids.data;
			}
			catch (Error e)
			{
				stderr.printf(@"I guess something is not working... $(e.message)\n");
			}

            // return something, whatever happened
			return result_ids.data;
        }

        private async HashTable<string, Variant>? get_meta_for_id(string id)
        {
            string shader_uri = @"https://www.shadertoy.com/api/v1/shaders/$id?key=$(ShadertoySearch.API_KEY)";
			var shader_message = new Soup.Message("GET", shader_uri);
			shader_message.priority = Soup.MessagePriority.VERY_HIGH;
			InputStream shader_stream;

            try
            {
			    shader_stream = yield _search_session.send_async(shader_message);
			}
            catch (Error e)
			{
				return null;
			}

			try
			{
                var shader_parser = new Json.Parser();
                yield shader_parser.load_from_stream_async(shader_stream);

				if (shader_parser.get_root() == null)
				{
				    return null;
				}

				if (shader_parser.get_root().get_object().has_member("Error"))
				{
				    return null;
				}

				var shader_root = shader_parser.get_root().get_object().get_object_member("Shader");
				var info_node = shader_root.get_object_member("info");

				string shader_name = info_node.get_string_member("name");
				string description = info_node.get_string_member("description");

				var meta = new HashTable<string, Variant>(str_hash, str_equal);
				meta.insert("name", shader_name);
                meta.insert("description", description);

                return meta;
			}
			catch (Error e)
			{
				stderr.printf("Could not load shader with id $id\n");
			}

			return null;
        }

        public async string[] get_initial_result_set(string[] terms) throws GLib.DBusError, GLib.IOError
        {
            return yield search_shaders(string.joinv(" ", terms));
        }

        public async string[] get_subsearch_result_set(string[] previous_results, string[] terms) throws GLib.DBusError, GLib.IOError
        {
            return yield search_shaders(string.joinv(" ", terms));
        }

        public async HashTable<string, Variant>[] get_result_metas(string[] results) throws GLib.DBusError, GLib.IOError
        {
            var metas = new GenericArray<HashTable<string, Variant>>();
            int count = 0;

            _current_metas = new HashTable<string, string>(str_hash, str_equal);

            foreach (var id in results)
            {
                var meta = yield get_meta_for_id(id);

                count++;

                if (meta != null)
                {
                    meta.insert("id", count.to_string());
                    metas.add(meta);

                    _current_metas.insert( count.to_string(), id);
                }
            }

            return metas.data;
        }

        public void activate_result(string result, string[] terms, uint32 timestamp) throws GLib.DBusError, GLib.IOError
        {
            activate(_current_metas[result]);
        }

        public async void launch_search(string[] terms, uint32 timestamp) throws GLib.DBusError, GLib.IOError
        {
        }
    }
}

