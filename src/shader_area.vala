using GL;
using Gtk;
using Gdk;
using Shady.Core;

namespace Shady
{
	public class ShaderArea : GLArea
	{
		public signal void initialized();

		public double fps { get; protected set; }
		public double time { get; protected set; }

		/* Time variables */
		protected float _year;
		protected float _month;
		protected float _day;
		protected float _seconds;

		protected float _delta;

		protected float _samplerate = 44100.0f;

		/* Initialized */
		protected bool _initialized = false;
		protected bool _size_updated = false;

		/* Mouse variables */
		protected bool _button_pressed;
		protected double _button_pressed_x;
		protected double _button_pressed_y;
		protected double _button_released_x;
		protected double _button_released_y;

		protected double _mouse_x = 0;
		protected double _mouse_y = 0;

		/* Shader render buffer variables */

		protected int _width = 0;
		protected int _height = 0;

		private Mutex _size_mutex = Mutex();

		public ShaderArea()
		{
			resize.connect((width, height) =>
			{
				_size_mutex.lock();

				_width = width;
				_height = height;

				_size_updated = true;

				if(!_initialized)
				{
					_initialized = true;
					initialized();
				}

				_size_mutex.unlock();
			});
		}

		public static Shader? get_default_shader()
		{
			Shader default_shader = new Shader();
			Shader.Renderpass renderpass = new Shader.Renderpass();

			try
			{
				string default_code = (string) (resources_lookup_data("/org/hasi/shady/data/shader/default.glsl", 0).get_data());
				renderpass.code = default_code;
			}
			catch(Error e)
			{
				print("Couldn't load default shader!\n");
				return null;
			}

			renderpass.type = Shader.RenderpassType.IMAGE;
			renderpass.name = "Image";

			default_shader.renderpasses.append_val(renderpass);

			return default_shader;
		}
	}
}
