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

			public int[] tex_widths;
			public int[] tex_heights;
			public int[] tex_depths;

			public GLuint tile_render_buf;

			public int cur_x_img_part;
			public int cur_y_img_part;

			public uint x_img_parts;
			public uint y_img_parts;

			public bool second_resize;

			public bool parts_rendered;
			public bool updated;

			public int frame_counter;
			
			public double time;
			public double delta;

			public float year;
			public float month;
			public float day;
			public float seconds;

			public int64 curr_time;

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

		private BufferProperties[] _buffer_props1 = {};
		private BufferProperties[] _buffer_props2 = {};

		private uint _image_prop_index1;
		private uint _image_prop_index2;

		public RenderResources()
		{
	 	}

		public BufferProperties get_image_prop(Purpose purpose)
		{
			if (!_buffer_switch && purpose == Purpose.RENDER || _buffer_switch && purpose == Purpose.COMPILE)
			{
				return _buffer_props1[_image_prop_index1];
			}
			else
			{
				return _buffer_props2[_image_prop_index2];
			}
		}

		public uint get_image_prop_index(Purpose purpose)
		{
			if (!_buffer_switch && purpose == Purpose.RENDER || _buffer_switch && purpose == Purpose.COMPILE)
			{
				return _image_prop_index1;
			}
			else
			{
				return _image_prop_index2;
			}
		}

		public void set_image_prop_index(Purpose purpose, uint index)
		{
			if (!_buffer_switch && purpose == Purpose.RENDER || _buffer_switch && purpose == Purpose.COMPILE)
			{
				_image_prop_index1 = index;
			}
			else
			{
				_image_prop_index2 = index;
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

		public void set_buffer_props(Purpose purpose, BufferProperties[] buffer_props)
		{
			if (!_buffer_switch && purpose == Purpose.RENDER || _buffer_switch && purpose == Purpose.COMPILE)
			{
				_buffer_props1 = buffer_props;
			}
			else
			{
				_buffer_props2 = buffer_props;
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
