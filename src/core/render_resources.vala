using GL;

namespace Shady.Core
{
	public class RenderResources
	{
		public class BufferProperties
		{
			public GLuint program;
			public GLuint fb;
			public GLuint vao;

			public GLuint tex_id_out_front;
			public GLuint tex_id_out_back;

			public Gdk.GLContext context;

			public GLuint[] tex_ids;
			public GLuint[] sampler_ids;
			public GLuint[] tex_targets;
			public int[] tex_channels;

			public int[,] tex_out_refs;
			public int[] tex_out_refs_img;

			public int[] tex_widths;
			public int[] tex_heights;
			public int[] tex_depths;

			public int cur_x_img_part;
			public int cur_y_img_part;

			//public double[] tex_times;

			public GLint date_loc;
			public GLint time_loc;
			public GLint channel_time_loc;
			public GLint delta_loc;
			public GLint fps_loc;
			public GLint frame_loc;
			public GLint res_loc;
			public GLint channel_res_loc;
			public GLint mouse_loc;
			public GLint samplerate_loc;
			public GLint[] channel_locs;
			public GLint offset_loc;
		}

		public enum Purpose
		{
			COMPILE,
			RENDER;
		}

		private bool _buffer_switch = false;

		public Mutex buffer_switch_mutex = Mutex();

		private BufferProperties _image_prop1 = new BufferProperties();
		private BufferProperties _image_prop2 = new BufferProperties();

		private BufferProperties[] _buffer_props1 = {};
		private BufferProperties[] _buffer_props2 = {};

		public RenderResources()
		{
	 	}

		public BufferProperties get_image_prop(Purpose purpose)
		{
			if (!_buffer_switch && purpose == Purpose.RENDER || _buffer_switch && purpose == Purpose.COMPILE)
			{
				return _image_prop1;
			}
			else
			{
				return _image_prop2;
			}
		}

		public BufferProperties[] get_buffer_props(Purpose purpose)
		{
			if (!_buffer_switch && purpose == Purpose.RENDER || _buffer_switch && purpose == Purpose.COMPILE)
			{
				return _buffer_props1;
			}
			else
			{
				return _buffer_props2;
			}
		}

		public void switch_buffer()
		{
			buffer_switch_mutex.lock();
			_buffer_switch=!_buffer_switch;
			buffer_switch_mutex.unlock();
		}
	}
}
