namespace Shady
{
    [DBus (name = "org.gnome.Shell.SearchProvider2")]
    public class SearchProvider : Object
    {
        [DBus (visible = false)]
        public signal void activate (uint32 timestamp);

        public static int64 _last_call = -1;
        public static int64 _last_call_sub = -1;

        public async string[] get_initial_result_set(string[] terms) throws GLib.DBusError, GLib.IOError
        {
            GenericArray<string> copy = new GenericArray<string>();

            string search_str = string.joinv(" ", terms);
            ShadertoySearch shadertoy_search = new ShadertoySearch();

            string[]? result_ids = shadertoy_search.search_shader_ids(search_str);

            if (result_ids != null)
            {
                foreach (string? result_id in result_ids)
                {
                    if (result_id != null)
                    {
                        copy.add(result_id);
                    }
                }
            }

            return copy.data;
        }

        public async string[] get_subsearch_result_set(string[] previous_results, string[] terms) throws GLib.DBusError, GLib.IOError
        {
            GenericArray<string> copy = new GenericArray<string>();

            string search_str = string.joinv(" ", terms);
            ShadertoySearch shadertoy_search = new ShadertoySearch();

            string[]? result_ids = shadertoy_search.search_shader_ids(search_str);

            if (result_ids != null)
            {
                foreach (string? result_id in result_ids)
                {
                    if (result_id != null)
                    {
                        print(result_id + "\n");
                        copy.add(result_id);
                    }
                }
            }

            return copy.data;
        }

        public async HashTable<string, Variant>[] get_result_metas(string[] results) throws GLib.DBusError, GLib.IOError
        {
            print("get_result_metas\n");

            var metas = new GenericArray<HashTable<string, Variant>>();
            int count = 0;

            foreach (var id in results)
            {
                ShadertoySearch shadertoy_search = new ShadertoySearch();
                Shader[] found = yield shadertoy_search.search("id:" + id);

                // there will be one result at maximum
                if (found.length > 0)
                {
                    var meta = new HashTable<string, Variant>(str_hash, str_equal);
                    var shader = found[0];

                    count++;

                    print(shader.shader_name + "\n\n");

                    meta.insert("id", count.to_string());
                    meta.insert("name", shader.shader_name);
                    meta.insert("description", shader.description);

                    metas.add(meta);
                }
            }

            //while (metas.data.length != results.length) Thread.usleep(1);

            return metas.data;
        }

        public void activate_result(string result, string[] terms, uint32 timestamp) throws GLib.DBusError, GLib.IOError
        {
            activate(timestamp);
        }

        public async void launch_search(string[] terms, uint32 timestamp) throws GLib.DBusError, GLib.IOError
        {
        }
    }
}

